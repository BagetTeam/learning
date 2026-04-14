from dataclasses import dataclass
from pathlib import Path
import logging
from copy import deepcopy
from typing import Any

from browsergym.core.env import BrowserEnv

from agentlab.benchmarks.abstract_env import (
    AbstractEnv,
    AbstractEnvArgs,
)

from webarena_pro.benchmark.task import WebArenaProTask, WebArenaProTaskConfig
from webarena_pro.utils import print_last_step_output, LastStepOutputType

logger = logging.getLogger(__name__)


class WebArenaProBrowserEnv(BrowserEnv):
    """
    Customized BrowserEnv for WebArenaPro.
    """

    last_step_output: LastStepOutputType = None

    def post_step(
        self, info: dict[str, Any], validate: bool = True
    ) -> tuple[dict[str, Any], float, bool, bool, dict[str, Any]]:
        obs, reward, terminated, truncated, info = super().post_step(info, validate)
        if not hasattr(self, "episode_info") or self.episode_info is None:
            print(
                "[WebArenaProBrowserEnv.post_step] Episode info not found, initializing to empty list"
            )
            self.episode_info = []
        else:
            print(
                "[WebArenaProBrowserEnv.post_step] Length of episode_info:",
                len(self.episode_info),
            )

        # super().post_step() calls self._task_validate() internally, which calls task.validate()
        self.last_step_output = {
            "obs": deepcopy(obs),
            "reward": reward,
            "terminated": terminated,
            "truncated": truncated,
            "info": info,
            "episode_info": self.episode_info,
        }

        print_last_step_output(self.last_step_output, func_name="post_step")
        return obs, reward, terminated, truncated, info

    def register_episode_info(self, episode_info):
        if hasattr(self, "episode_info"):
            # warn that the episode_info is being overwritten
            logger.warning(
                "The episode_info is being overwritten. This may not be intended."
            )
        self.episode_info = episode_info

    def _task_validate(self):
        prev_active_page = self.page
        prev_page_history = self.page_history.copy()
        # call validate
        print_last_step_output(self.last_step_output, func_name="_task_validate")

        reward, done, user_message, info = self.task.validate(
            self.page, self.chat.messages, last_step_output=self.last_step_output
        )

        # safety fix, in case validate() did mess up the active page and/or page history
        if prev_active_page != self.page or prev_page_history != self.page_history:
            logger.debug(
                "The active page and / or page history has changed during task.validate(). A recovery fix will be applied."
            )
            self.page = prev_active_page
            self.page_history = prev_page_history

        return reward, done, user_message, info


@dataclass
class WebArenaProEnvArgs(AbstractEnvArgs):
    task_config: WebArenaProTaskConfig
    task_name: str
    task_seed: int = 0
    max_steps: int = 30
    action_space: str = "bid"

    def make_env(
        self,
        exp_dir: Path,
        action_mapping=None,
        use_raw_page_output: bool = False,
    ) -> "WebArenaProEnv":
        return WebArenaProEnv(
            self,
            action_mapping=action_mapping,
            use_raw_page_output=use_raw_page_output,
        )
    

class WebArenaProEnv(AbstractEnv, WebArenaProBrowserEnv):
    def __init__(self, env_args: WebArenaProEnvArgs, **kwargs):
        self.env_args = env_args
        WebArenaProBrowserEnv.__init__(
            self,
            task_entrypoint=WebArenaProTask,
            task_kwargs={"config": env_args.task_config},
            **kwargs,
        )

        self.steps_taken = 0

    def reset(self, seed=None):
        self.steps_taken = 0
        return WebArenaProBrowserEnv.reset(self, seed)

    def step(self, action):
        assert isinstance(action, str), (
            "Action must be a string of Python code to execute in the browser environment."
        )
        obs, reward, terminated, truncated, info = WebArenaProBrowserEnv.step(
            self, action
        )
        self.steps_taken += 1
        if not terminated and self.steps_taken >= self.env_args.max_steps:
            truncated = True
        return obs, reward, terminated, truncated, info

    def close(self):
        WebArenaProBrowserEnv.close(self)
