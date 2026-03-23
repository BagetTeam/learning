from datetime import datetime
import re
import numpy as np
import traceback
import gzip
import json
import logging
import pickle
import uuid
from dataclasses import dataclass
from pathlib import Path

from browsergym.experiments.loop import StepInfo, _extract_err_msg, _aggregate_episode_stats
from browsergym.experiments.loop import _send_chat_info, save_package_versions
from browsergym.experiments.loop import _is_debugging
import gymnasium as gym
from browsergym.experiments.benchmark.base import Benchmark
from browsergym.core.env import BrowserEnv
from bgym import DEFAULT_BENCHMARKS

from agentlab.agents.agent_args import AgentArgs, AbstractAgentArgs
from agentlab.analyze import inspect_results
from agentlab.experiments import reproducibility_util as repro
from agentlab.experiments.loop import _move_old_exp
from agentlab.experiments.exp_utils import RESULTS_DIR, add_dependencies
from agentlab.experiments.launch_exp import (
    find_incomplete,
    non_dummy_count,
    run_experiments,
)
from browsergym.core.chat import Chat
from agentlab.experiments.study import Study, EnvArgs, ExpArgs, set_demo_mode, _make_study_name, get_most_recent_study, _convert_env_args

try:
    from agentlab.agents.tapeagent import TapeAgent, save_tape
except ImportError:
    TapeAgent = None

from webarena_pro.benchmark.env import WebArenaProBrowserEnv

SEED_MAX = 2 ^ 32  # arbitrary max value (exclusive), seems large enough

logger = logging.getLogger(__name__)


class WebArenaProStepInfo(StepInfo):
    def from_step(self, env: BrowserEnv, action: str, obs_preprocessor: callable):
        # The code below calls env.step(action) which calls env.post_step()
        super().from_step(env, action, obs_preprocessor)

@dataclass
class WebArenaProExpArgs(ExpArgs):
    """Arguments to run an experiment, i.e. run agent in an environment until done.

    This dataclass is used to store experiments arguments. It contains
    agent_args and env_args which follows the same principle. It contains helper
    functions to prepare and run experiments.

    Attributes:
    -----------
    agent_args: AbstractAgentArgs
        The arguments to instantiate the agent.
    env_args: EnvArgs
        The arguments to instantiate the environment.
    exp_dir: str
        The directory where the experiment will be saved.
    exp_name: str
        The name of the experiment. If None, it will be generated from the
        agent and environment names.
    enable_debug: bool
        If python is running in debug mode and `enable_debug` is True, errors
        will be raised instead of only logged
    error_msg: str
        Error that occured while running the experiment (if any).
    stack_trace: str
        Stack trace of the error (if any).
    order: int (internal)
        The order of the experiment in the batch. It is used to keep track of
        the original order of the experiments in case they are shuffled.
    """

    agent_args: AbstractAgentArgs
    env_args: EnvArgs
    exp_dir: str = None
    exp_name: str = None
    enable_debug: bool = True
    err_msg: str = None
    stack_trace: str = None
    order: int = None  # use to keep the original order the experiments were meant to be launched.
    logging_level: int = logging.INFO
    logging_level_stdout: int = logging.INFO
    exp_id: str = None
    depends_on: tuple[str] = ()
    save_screenshot: bool = True
    save_som: bool = False

    def make_id(self):
        super().make_id()

    def prepare(self, exp_root):
        super().prepare(exp_root)

    def run(self):
        """Run the experiment and save the results"""
        # start writing logs to run logfile
        self._set_logger()

        # log python environment info
        save_package_versions(Path(self.exp_dir))

        episode_info = []
        agent = None
        env, step_info, err_msg, stack_trace = None, None, None, None
        try:
            logger.info(f"Running experiment {self.exp_name} in:\n  {self.exp_dir}")
            agent = self.agent_args.make_agent()
            if hasattr(agent, "set_task_name"):
                agent.set_task_name(self.env_args.task_name)

            logger.debug("Agent created.")

            env = self.env_args.make_env(
                action_mapping=agent.action_set.to_python_code,
                exp_dir=self.exp_dir,
                use_raw_page_output=getattr(self.agent_args, "use_raw_page_output", False),
            )


            logger.debug("Environment created.")
            step_info = WebArenaProStepInfo(step=0)  # TODO: Use WebSynthStepInfo instead of StepInfo once the former is fixed
            episode_info = [step_info]
            step_info.from_reset(
                env, seed=self.env_args.task_seed or 0, obs_preprocessor=agent.obs_preprocessor
            )
            logger.debug("Environment reset.")

            if not hasattr(env.unwrapped, "register_episode_info"):
                raise ValueError("The environment does not have a register_episode_info method. Make sure you are using the BrowserEnvWebSynth class.")
            env.unwrapped.register_episode_info(episode_info)
            
            while not step_info.is_done:  # set a limit
                logger.debug(f"Starting step {step_info.step}.")
                action = step_info.from_action(agent)
                logger.debug(f"Agent chose action:\n {action}")

                # agent_info_dict = {
                #     "chat_messages": step_info.agent_info.chat_messages.to_openai(),
                #     "thought": step_info.agent_info.think,
                #     "action": action,
                #     "extra_info": step_info.agent_info.extra_info,
                # }

                if action is None:
                    # will end the episode after saving the step info.
                    step_info.truncated = True

                step_info.save_step_info(
                    self.exp_dir, save_screenshot=self.save_screenshot, save_som=self.save_som
                )
                logger.debug("Step info saved.")

                if hasattr(env.unwrapped, "chat") and isinstance(env.unwrapped.chat, Chat):
                    _send_chat_info(env.unwrapped.chat, action, step_info.agent_info)
                    logger.debug("Chat info sent.")

                if action is None:
                    logger.debug("Agent returned None action. Ending episode.")
                    break

                logger.debug("Sending action to environment.")

                step_info = WebArenaProStepInfo(step=step_info.step + 1)  # TODO: Use WebSynthStepInfo instead of StepInfo once the former is fixed
                episode_info.append(step_info)
                step_info.exp_dir = self.exp_dir
                print("[WebArenaProExpArgs.run] Length of episode_info:", len(episode_info))
                
                step_info.from_step(env, action, obs_preprocessor=agent.obs_preprocessor)
                logger.debug("Environment stepped.")
                if step_info.is_done:
                    logger.debug(
                        f"Episode done: terminated: {step_info.terminated}, truncated: {step_info.truncated}."
                    )
                

        except Exception as e:
            err_msg = f"Exception uncaught by agent or environment in task {self.env_args.task_name}.\n{type(e).__name__}:\n{e}"
            stack_trace = traceback.format_exc()

            self.err_msg = err_msg
            self.stack_trace = stack_trace

            logger.warning(err_msg + "\n" + stack_trace)
            if _is_debugging() and self.enable_debug:
                logger.warning("Debug mode is enabled. Raising the error.")
                raise

        finally:
            try:
                if step_info is not None:
                    step_info.save_step_info(
                        self.exp_dir, save_screenshot=self.save_screenshot, save_som=self.save_som
                    )
            except Exception as e:
                logger.error(f"Error while saving step info in the finally block: {e}")
            try:
                if (
                    not err_msg
                    and len(episode_info) > 0
                    and not (episode_info[-1].terminated or episode_info[-1].truncated)
                ):
                    e = KeyboardInterrupt("Early termination??")
                    err_msg = f"Exception uncaught by agent or environment in task {self.env_args.task_name}.\n{type(e).__name__}:\n{e}"
                logger.info("Saving experiment info.")
                self.save_summary_info(episode_info, Path(self.exp_dir), err_msg, stack_trace)
                if TapeAgent is not None and isinstance(agent, TapeAgent):
                    task = getattr(env, "task", {})
                    save_tape(self.exp_dir, episode_info, task, agent.final_tape)
            except Exception as e:
                logger.exception(f"Error while saving experiment info: {e}")
            try:
                if env is not None:
                    env.close()
            except Exception as e:
                logger.exception(f"Error while closing the environment: {e}")
            try:
                self._unset_logger()  # stop writing logs to run logfile
            except Exception as e:
                logger.exception(f"Error while unsetting the logger: {e}")

    def save_summary_info(
        self,
        episode_info: list[WebArenaProStepInfo],
        exp_dir: Path,
        err_msg: str | None,
        stack_trace: str | None,
    ):
        super().save_summary_info(episode_info, exp_dir, err_msg, stack_trace)


@dataclass
class WebArenaProStudy(Study):
    agent_args: list[AgentArgs] = None
    benchmark: Benchmark | str = None
    dir: Path = None
    suffix: str = ""  # used for adding a personnal comment to the study name
    uuid: str = None
    reproducibility_info: dict = None
    logging_level: int = logging.DEBUG
    logging_level_stdout: int = logging.WARNING
    comment: str = None  # Extra comments from the authors of this study
    ignore_dependencies: bool = False
    avg_step_timeout: int = 60
    demo_mode: bool = False
    
    def run(
        self,
        n_jobs=1,
        parallel_backend="ray",
        strict_reproducibility=False,
        n_relaunch=3,
        relaunch_errors=True,
        exp_root=RESULTS_DIR,
    ):
        self.set_reproducibility_info(
            strict_reproducibility=strict_reproducibility, comment=self.comment
        )
        self.save(exp_root=exp_root)

        n_exp = len(self.exp_args_list)
        last_error_count = None

        for i in range(n_relaunch):
            logger.info(f"Launching study {self.name} - trial {i + 1} / {n_relaunch}")
            self._run(n_jobs, parallel_backend, strict_reproducibility)

            suffix = f"trial_{i + 1}_of_{n_relaunch}"
            _, summary_df, error_report = self.get_results(suffix=suffix)
            logger.info("\n" + str(summary_df))

            n_incomplete, n_error = self.find_incomplete(include_errors=relaunch_errors)

            if n_error / n_exp > 0.3:
                logger.warning("More than 30% of the experiments errored. Stopping the retries.")
                break

            if last_error_count is not None and n_error >= last_error_count:
                logger.warning(
                    "Last trial did not reduce the number of errors. Stopping the retries."
                )
                break

            if n_incomplete == 0:
                logger.info(f"Study {self.name} finished.")
                break

        logger.info("# Error Report:\n-------------\n\n" + error_report)

        if n_incomplete != 0:
            logger.warning(
                f"Study {self.name} did not finish after {n_relaunch} trials. There are {n_incomplete} incomplete experiments."
            )

    def _run(self, n_jobs=1, parallel_backend="joblib", strict_reproducibility=False):
        """Run all experiments in the study in parallel when possible.

        Args:
            n_jobs: int
                Number of parallel jobs.
            parallel_backend: str
                Parallel backend to use. Either "joblib", "ray" or "sequential".
            strict_reproducibility: bool
                If True, all modifications have to be committed before running the experiments.
                Also, if relaunching a study, it will not be possible if the code has changed.

        Raises:
            ValueError: If the exp_args_list is None.
        """

        if self.exp_args_list is None:
            raise ValueError("exp_args_list is None. Please set exp_args_list before running.")

        logger.info("Preparing backends...")
        self.benchmark.prepare_backends()
        logger.info("Backends ready.")

        run_experiments(
            n_jobs,
            self.exp_args_list,
            self.dir,
            parallel_backend=parallel_backend,
            avg_step_timeout=self.avg_step_timeout,
        )

    @property
    def name(self):
        agent_names = [a.agent_name for a in self.agent_args]
        return _make_study_name(agent_names, [self.benchmark.name], self.suffix)

    def override_max_steps(self, max_steps):
        for exp_args in self.exp_args_list:
            exp_args.env_args.max_steps = max_steps

    @staticmethod
    def load(dir: Path) -> "WebArenaProStudy":
        dir = Path(dir)
        study_path = dir / "study.pkl.gz"
        if not study_path.exists() and dir.is_dir():
            # For backward compatibility
            first_result = next(
                inspect_results.yield_all_exp_results(savedir_base=dir, progress_fn=None)
            )
            benchmark_name = first_result.exp_args.env_args.task_name.split(".")[0]
            agent_args = first_result.exp_args.agent_args
            study = WebArenaProStudy(agent_args=agent_args, benchmark=benchmark_name, dir=dir)
        else:
            with gzip.open(dir / "study.pkl.gz", "rb") as f:
                study = pickle.load(f)  # type: WebArenaProStudy
            study.dir = dir

            # # just a check
            # for i, exp_args in enumerate(study.exp_args_list):
            #     if exp_args.order != i:
            #         logging.warning(f"The order of the experiments is not correct. {exp_args.order} != {i}")

        return study

    @staticmethod
    def load_most_recent(root_dir: Path = None, contains=None) -> "WebArenaProStudy":
        return WebArenaProStudy.load(get_most_recent_study(root_dir, contains=contains))

    def agents_on_benchmark(
        self,
        agents: list[AgentArgs] | AgentArgs,
        benchmark: Benchmark,
        demo_mode=False,
        logging_level: int = logging.INFO,
        logging_level_stdout: int = logging.INFO,
        ignore_dependencies=False,
    ):
        """Run one or multiple agents on a benchmark.

        Args:
            agents: list[AgentArgs] | AgentArgs
                The agent configuration(s) to run.
            benchmark: Benchmark
                The benchmark to run the agents on.
            demo_mode: bool
                If True, the experiments will be run in demo mode.
            logging_level: int
                The logging level for individual jobs.
            logging_level_stdout: int
                The logging level for the stdout.
            ignore_dependencies: bool
                If True, the dependencies will be ignored and all experiments can be run in parallel.

        Returns:
            list[WebSynthExpArgs]: The list of experiments to run.

        Raises:
            ValueError: If multiple agents are run on a benchmark that requires manual reset.
        """

        if not isinstance(agents, (list, tuple)):
            agents = [agents]

        if benchmark.name.startswith("visualwebarena") or benchmark.name.startswith("webarena"):
            if len(agents) > 1:
                raise ValueError(
                    f"Only one agent can be run on {benchmark.name} since the instance requires manual reset after each evaluation."
                )

        for agent in agents:
            agent.set_benchmark(
                benchmark, demo_mode
            )  # the agent can adapt (lightly?) to the benchmark

        env_args_list = benchmark.env_args_list
        if demo_mode:
            set_demo_mode(env_args_list)

        exp_args_list = []

        for agent in agents:
            for env_args in env_args_list:
                exp_args = WebArenaProExpArgs(
                    agent_args=agent,
                    env_args=env_args,
                    logging_level=logging_level,
                    logging_level_stdout=logging_level_stdout,
                )
                exp_args_list.append(exp_args)

        for i, exp_args in enumerate(exp_args_list):
            exp_args.order = i

        # not required with ray, but keeping around if we would need it for visualwebareana on joblib
        # _flag_sequential_exp(exp_args_list, benchmark)

        if not ignore_dependencies:
            # populate the depends_on field based on the task dependencies in the benchmark
            exp_args_list = add_dependencies(exp_args_list, benchmark.dependency_graph_over_tasks())
        else:
            logger.warning(
                f"Ignoring dependencies for benchmark {benchmark.name}. This could lead to different results."
            )

        return exp_args_list
