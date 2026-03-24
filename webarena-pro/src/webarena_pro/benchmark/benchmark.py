import json
import logging
from pathlib import Path
from typing import Any, Literal

from browsergym.experiments.benchmark.base import HighLevelActionSetArgs
from browsergym.experiments.benchmark.configs import DEFAULT_HIGHLEVEL_ACTION_SET_ARGS

from agentlab.benchmarks.abstract_env import AbstractBenchmark

from .env import WebArenaProEnvArgs
from .task import WebArenaProTaskConfig


logger = logging.getLogger(__name__)


class WebArenaProBenchmark(AbstractBenchmark):
    name: str = "webarena-pro"
    is_multi_tab: bool = True
    high_level_action_set_args: HighLevelActionSetArgs = DEFAULT_HIGHLEVEL_ACTION_SET_ARGS[
        "webarena"
    ]  # similar to webarena
    env_args_list: list["WebArenaProEnvArgs"] = None  # type: ignore
    task_dependencies: dict[str, list[str]] = None  # type: ignore

    test_set_path: str = str(Path(__file__).parent.parent / "config" / "test.raw.json")

    def __post_init__(self):
        self._load_tasks()

    def model_post_init(self, context):
        """Load tasks from the JSON file and create self.env_args_list."""
        self._load_tasks()

    def _load_tasks(self) -> None:
        self.env_args_list = []
        self.task_dependencies = {}
        previous_task_by_website: dict[str, str] = {}
        test_set_file = Path(self.test_set_path)
        with test_set_file.open("r", encoding="utf-8") as handle:
            raw_tasks = json.load(handle)

        if not isinstance(raw_tasks, list):
            raise ValueError(
                f"Expected list of task objects in {test_set_file}, got {type(raw_tasks).__name__}."
            )

        for index, raw_task in enumerate(raw_tasks):
            if not isinstance(raw_task, dict):
                raise ValueError(
                    f"Task at index {index} in {test_set_file} is not an object/dict."
                )
            task_id = str(raw_task.get("task_id", f"task-{index}"))
            safe_task_id = task_id.replace("_", "-").replace(" ", "-").lower()
            container_name = f"webarena-pro-{safe_task_id}-{index}"
            task_config = WebArenaProTaskConfig.from_raw_task(
                raw_task=raw_task,
                container_name=container_name,
            )
            task_name = f"{self.name}.{task_config.task_id}"
            env_args = WebArenaProEnvArgs(task_config=task_config, task_name=task_name)
            self.env_args_list.append(env_args)

            previous_task_name = previous_task_by_website.get(task_config.website)
            self.task_dependencies[task_name] = [previous_task_name] if previous_task_name else []
            previous_task_by_website[task_config.website] = task_name

        logger.info("Loaded %s tasks from %s", len(self.env_args_list), test_set_file)

    def dependency_graph_over_tasks(self) -> dict[str, list[str]]:
        return dict(self.task_dependencies)

