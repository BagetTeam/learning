"""Rule-based evaluators for checking task success."""

import logging
import re
from typing import TYPE_CHECKING

from metabase_agent.evaluation.base import EvaluationResult

if TYPE_CHECKING:
    from metabase_agent.agent.models import Observation
    from metabase_agent.logging.traces import StepTrace
    from metabase_agent.tasks.models import TaskSpec


class RuleBasedEvaluator:
    """Evaluator that checks success criteria using simple rules.

    Supports criteria like:
    - url_contains: <substring>
    - url_matches: <regex>
    - title_contains: <substring>
    - text_contains: <substring>
    - saved_question_exists
    - file_downloaded
    """

    def __init__(self) -> None:
        self.logger = logging.getLogger(__name__)

    def evaluate(
        self,
        task: "TaskSpec",
        traces: list["StepTrace"],
        final_observation: "Observation",
    ) -> EvaluationResult:
        """Evaluate the task using rule-based criteria."""
        if not task.success_criteria:
            return EvaluationResult.failed("No success criteria defined")

        passed_criteria: list[str] = []
        failed_criteria: list[str] = []

        for criterion in task.success_criteria:
            criterion_str = str(criterion) if isinstance(criterion, dict) else criterion
            if self._check_criterion(criterion, final_observation, traces):
                passed_criteria.append(criterion_str)
            else:
                failed_criteria.append(criterion_str)

        if failed_criteria:
            return EvaluationResult.failed(
                f"Failed criteria: {', '.join(failed_criteria)}",
                score=len(passed_criteria) / len(task.success_criteria),
            )

        return EvaluationResult.passed(
            f"All criteria passed: {', '.join(passed_criteria)}",
            score=1.0,
        )

    def _check_criterion(
        self,
        criterion: str | dict,
        observation: "Observation",
        traces: list["StepTrace"],
    ) -> bool:
        """Check a single criterion.
        
        Criterion can be:
        - A string like "saved_question_exists" or "title_contains: Canada"
        - A dict like {"title_contains": "Canada"} (from YAML parsing)
        """
        if isinstance(criterion, dict):
            if len(criterion) != 1:
                self.logger.warning(f"Invalid dict criterion format: {criterion}")
                return False
            key = list(criterion.keys())[0]
            value = str(criterion[key])
        elif ":" in criterion:
            key, value = criterion.split(":", 1)
            key = key.strip()
            value = value.strip()
        else:
            key = criterion.strip()
            value = ""

        if key == "url_contains":
            return value.lower() in observation.url.lower()

        elif key == "url_matches":
            return bool(re.search(value, observation.url))

        elif key == "title_contains":
            return value.lower() in observation.title.lower()

        elif key == "text_contains":
            return value.lower() in observation.text_content.lower()

        elif key == "saved_question_exists":
            return self._check_question_saved(observation, traces)

        elif key == "file_downloaded":
            return self._check_file_downloaded(traces)

        elif key == "file_extension":
            return self._check_file_extension(traces, value)

        else:
            self.logger.warning(f"Unknown criterion: {key}")
            return False

    def _check_question_saved(
        self,
        observation: "Observation",
        traces: list["StepTrace"],
    ) -> bool:
        """Check if a question was saved.

        This is a heuristic check - for robust verification,
        use the Metabase API via metabase/api.py.
        """
        save_indicators = [
            "saved" in observation.text_content.lower(),
            "/question/" in observation.url,
            "success" in observation.text_content.lower(),
        ]
        return any(save_indicators)

    def _check_file_downloaded(self, traces: list["StepTrace"]) -> bool:
        """Check if a file was downloaded during the run.

        TODO: Implement actual download detection by monitoring
        the downloads directory or browser download events.
        """
        self.logger.warning("File download check not fully implemented")
        return False

    def _check_file_extension(self, traces: list["StepTrace"], extension: str) -> bool:
        """Check if a file with the given extension was downloaded.

        TODO: Implement actual download verification.
        """
        self.logger.warning("File extension check not fully implemented")
        return False
