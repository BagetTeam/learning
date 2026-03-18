"""Task runner that orchestrates browser environment, agent, and evaluation."""

import logging
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import TYPE_CHECKING

from metabase_agent.agent.generic_agent_adapter import AgentController
from metabase_agent.agent.models import AgentAction
from metabase_agent.config import AppConfig
from metabase_agent.env.playwright_env import PlaywrightEnv
from metabase_agent.evaluation.rules import RuleBasedEvaluator
from metabase_agent.logging.artifacts import ArtifactLogger
from metabase_agent.logging.traces import StepTrace

if TYPE_CHECKING:
    from metabase_agent.tasks.models import TaskSpec


@dataclass
class RunResult:
    """Result of a task run."""

    success: bool
    summary: str
    error: str | None = None
    artifacts_dir: Path | None = None
    total_steps: int = 0
    elapsed_seconds: float = 0.0
    traces: list[StepTrace] = field(default_factory=list)


class TaskRunner:
    """Orchestrates running a task through the browser agent loop."""

    def __init__(self, config: AppConfig) -> None:
        self.config = config
        self.logger = logging.getLogger(__name__)

    def run(self, task: "TaskSpec") -> RunResult:
        """Execute a task and return the result."""
        start_time = time.time()

        run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        artifacts_dir = self.config.artifacts_dir / f"{task.id}_{run_id}"
        artifact_logger = ArtifactLogger(artifacts_dir)
        artifact_logger.save_task_spec(task)

        env = PlaywrightEnv(
            headless=self.config.headless,
            metabase_url=self.config.metabase.url,
            username=self.config.metabase.username,
            password=self.config.metabase.password,
        )

        agent = AgentController(
            model_name=self.config.model.name,
            api_key=self.config.model.api_key,
            base_url=self.config.model.base_url,
        )

        evaluator = RuleBasedEvaluator()

        traces: list[StepTrace] = []
        step = 0
        done = False
        error: str | None = None

        try:
            self.logger.info("Initializing browser environment")
            obs = env.reset(task)
            agent.reset(task)

            while step < task.max_steps and not done:
                step += 1
                step_start = time.time()
                self.logger.info(f"Step {step}/{task.max_steps}")

                action = agent.act(obs)
                self.logger.debug(f"Agent action: {action}")

                screenshot_path = artifact_logger.save_screenshot(
                    env.get_screenshot(),
                    step,
                    prefix="before",
                )

                obs, reward, done, info = env.step(action)

                trace = StepTrace(
                    step=step,
                    action=action,
                    observation_summary=obs.summary(),
                    url=obs.url,
                    screenshot_path=screenshot_path,
                    reward=reward,
                    done=done,
                    elapsed_ms=int((time.time() - step_start) * 1000),
                    error=info.get("error"),
                )
                traces.append(trace)
                artifact_logger.save_trace(trace)

                if done:
                    self.logger.info("Environment signaled done")
                    break

                evaluation = evaluator.evaluate(task, traces, obs)
                if evaluation.success:
                    self.logger.info(f"Task succeeded: {evaluation.reason}")
                    done = True
                    break

                if time.time() - start_time > task.timeout_seconds:
                    error = "Task timed out"
                    self.logger.warning(error)
                    break

        except Exception as e:
            error = str(e)
            self.logger.exception("Task failed with exception")

        finally:
            env.close()

        final_screenshot = artifact_logger.save_screenshot(
            env.get_screenshot() if hasattr(env, "_page") and env._page else None,
            step,
            prefix="final",
        )

        elapsed = time.time() - start_time
        success = done and error is None

        final_evaluation = evaluator.evaluate(task, traces, obs) if "obs" in locals() else None
        summary = (
            final_evaluation.reason if final_evaluation else "Task did not complete successfully"
        )

        result = RunResult(
            success=success,
            summary=summary if success else (error or "Unknown failure"),
            error=error,
            artifacts_dir=artifacts_dir,
            total_steps=step,
            elapsed_seconds=elapsed,
            traces=traces,
        )

        artifact_logger.save_summary(result)

        return result
