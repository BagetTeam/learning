"""Rule-based evaluators for checking task success."""

import logging
import re
from typing import TYPE_CHECKING

from metabase_agent.evaluation.base import EvaluationResult

if TYPE_CHECKING:
    from metabase_agent.agent.models import Observation
    from metabase_agent.logging.traces import StepTrace
    from metabase_agent.tasks.models import TaskSpec

def _get_metabase_token() -> str | None:
    """Authenticate with Metabase and return a session token."""
    try:
        resp = requests.post(
            f"{METABASE_URL}/api/session",
            json={"username": METABASE_USER, "password": METABASE_PASS},
            timeout=10,
        )
        resp.raise_for_status()
        return resp.json().get("id")
    except Exception:
        return None
 
 
def _metabase_get(path: str) -> dict | list | None:
    """Make an authenticated GET request to the Metabase API."""
    token = _get_metabase_token()
    if not token:
        return None
    try:
        resp = requests.get(
            f"{METABASE_URL}{path}",
            headers={"X-Metabase-Session": token},
            timeout=10,
        )
        resp.raise_for_status()
        return resp.json()
    except Exception:
        return None


class RuleBasedEvaluator:
    """Evaluator that checks success criteria using simple rules.

        Supported criteria
    ------------------
    Observation-based (fast, no API call):
      - url_contains: <substring>
      - url_matches: <regex>
      - title_contains: <substring>         # browser tab title
      - text_contains: <substring>          # visible page text
 
    Metabase API-based (reliable, requires credentials):
      - saved_question_exists               # any question was saved this run
      - question_name_contains: <substring> # question name matches (API)
      - dashboard_exists                    # any dashboard was created this run
      - dashboard_name_contains: <substring>
      - dashboard_card_count: <n>           # dashboard has at least N cards
      - subscription_exists                 # a pulse/subscription was created
      - alert_exists                        # a question alert was created
      - collection_permission_set           # a collection permission was changed
 
    Download / export:
      - file_downloaded                     # any file was downloaded
      - file_extension: <ext>               # downloaded file has extension (csv, pdf, json…)
 
    UI state (observation heuristics):
      - visualization_type: <type>          # bar, pie, line, table, map…
      - has_variable_filter                 # SQL query uses {{variable}} syntax
      - page_contains_chart                 # a chart element is visible
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

    # ------------------------------------------------------------------
    # Criterion dispatcher
    # ------------------------------------------------------------------
 
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

        # ---- observation-based ----
        if key == "url_contains":
            return value.lower() in observation.url.lower()

        elif key == "url_matches":
            return bool(re.search(value, observation.url))

        elif key == "title_contains":
            return value.lower() in observation.title.lower()

        elif key == "text_contains":
            return value.lower() in observation.text_content.lower()

        # ---- Metabase API-based ----
        elif key == "saved_question_exists":
            return self._check_question_saved_api(observation)
 
        elif key == "question_name_contains":
            return self._check_question_name(value)
 
        elif key == "dashboard_exists":
            return self._check_dashboard_exists(observation)
 
        elif key == "dashboard_name_contains":
            return self._check_dashboard_name(value)
 
        elif key == "dashboard_card_count":
            return self._check_dashboard_card_count(observation, int(value))
 
        elif key == "subscription_exists":
            return self._check_subscription_exists()
 
        elif key == "alert_exists":
            return self._check_alert_exists()
 
        elif key == "collection_permission_set":
            return self._check_collection_permission(observation)
 
        # ---- downloads ----
        elif key == "file_downloaded":
            return self._check_file_downloaded(traces)
 
        elif key == "file_extension":
            return self._check_file_extension(traces, value)
 
        # ---- UI state ----
        elif key == "visualization_type":
            return self._check_visualization_type(observation, value)
 
        elif key == "has_variable_filter":
            return self._check_variable_filter(observation, traces)
 
        elif key == "page_contains_chart":
            return self._check_page_contains_chart(observation)
 
        else:
            self.logger.warning(f"Unknown criterion: {key}")
            return False
 
    # ------------------------------------------------------------------
    # Metabase API checks
    # ------------------------------------------------------------------
 
    def _check_question_saved_api(self, observation: "Observation") -> bool:
        """
        Primary: verify via API that a card exists whose URL matches the
        current page (/question/123).
        Fallback: heuristic on observation text if API is unavailable.
        """
        # Try to extract question ID from URL first
        match = re.search(r"/question/(\d+)", observation.url)
        if match:
            question_id = match.group(1)
            data = _metabase_get(f"/api/card/{question_id}")
            if data and "id" in data:
                return True
 
        # Fallback: check if any card was recently created
        data = _metabase_get("/api/card?f=all&limit=5")
        if data:
            cards = data if isinstance(data, list) else data.get("data", [])
            if cards:
                return True
 
        # Last resort heuristic
        return any([
            "saved" in observation.text_content.lower(),
            "/question/" in observation.url,
        ])
 
    def _check_question_name(self, substring: str) -> bool:
        """Check that a recently saved question's name contains the substring."""
        data = _metabase_get("/api/card?f=all&limit=10")
        if not data:
            return False
        cards = data if isinstance(data, list) else data.get("data", [])
        return any(substring.lower() in (c.get("name") or "").lower() for c in cards)
 
    def _check_dashboard_exists(self, observation: "Observation") -> bool:
        """Check via API that a dashboard exists at the current URL."""
        match = re.search(r"/dashboard/(\d+)", observation.url)
        if match:
            dash_id = match.group(1)
            data = _metabase_get(f"/api/dashboard/{dash_id}")
            if data and "id" in data:
                return True
 
        # Fallback: check recent dashboards
        data = _metabase_get("/api/dashboard?limit=5")
        if data:
            dashboards = data if isinstance(data, list) else data.get("data", [])
            return bool(dashboards)
 
        return "/dashboard/" in observation.url
 
    def _check_dashboard_name(self, substring: str) -> bool:
        """Check that a dashboard with a matching name exists."""
        data = _metabase_get("/api/dashboard?limit=20")
        if not data:
            return False
        dashboards = data if isinstance(data, list) else data.get("data", [])
        return any(substring.lower() in (d.get("name") or "").lower() for d in dashboards)
 
    def _check_dashboard_card_count(
        self, observation: "Observation", min_cards: int
    ) -> bool:
        """Check that the current dashboard has at least min_cards cards."""
        match = re.search(r"/dashboard/(\d+)", observation.url)
        if not match:
            return False
        dash_id = match.group(1)
        data = _metabase_get(f"/api/dashboard/{dash_id}")
        if not data:
            return False
        cards = data.get("dashcards") or data.get("ordered_cards") or []
        return len(cards) >= min_cards
 
    def _check_subscription_exists(self) -> bool:
        """Check that at least one pulse/subscription exists."""
        data = _metabase_get("/api/pulse")
        if not data:
            return False
        pulses = data if isinstance(data, list) else data.get("data", [])
        return bool(pulses)
 
    def _check_alert_exists(self) -> bool:
        """Check that at least one question alert exists."""
        data = _metabase_get("/api/alert")
        if not data:
            return False
        alerts = data if isinstance(data, list) else data.get("data", [])
        return bool(alerts)
 
    def _check_collection_permission(self, observation: "Observation") -> bool:
        """
        Heuristic: agent landed on a permissions page and no error is shown.
        For a robust check, diff /api/collection/graph before and after.
        """
        on_permissions_page = "permissions" in observation.url.lower()
        no_error = "error" not in observation.text_content.lower()
        return on_permissions_page and no_error
 
    # ------------------------------------------------------------------
    # Download checks
    # ------------------------------------------------------------------
 
    def _check_file_downloaded(self, traces: list["StepTrace"]) -> bool:
        """
        Check traces for a network response with a Content-Disposition header
        or a Metabase export URL pattern.
        """
        export_url_patterns = [
            r"/api/card/\d+/query/csv",
            r"/api/card/\d+/query/json",
            r"/api/card/\d+/query/xlsx",
            r"/api/dashboard/\d+/export",
        ]
        for trace in traces:
            for event in getattr(trace, "network_events", []):
                url = getattr(event, "url", "")
                for pattern in export_url_patterns:
                    if re.search(pattern, url):
                        return True
                headers = getattr(event, "response_headers", {})
                if "content-disposition" in {k.lower() for k in headers}:
                    return True
        return False
 
    def _check_file_extension(self, traces: list["StepTrace"], extension: str) -> bool:
        """Check that a downloaded file matches the expected extension."""
        ext = extension.lower().lstrip(".")
        export_url_patterns = {
            "csv": r"/query/csv",
            "json": r"/query/json",
            "xlsx": r"/query/xlsx",
            "pdf": r"/export|/pdf",
        }
        pattern = export_url_patterns.get(ext, rf"\.{ext}")
        for trace in traces:
            for event in getattr(trace, "network_events", []):
                url = getattr(event, "url", "")
                if re.search(pattern, url):
                    return True
        return False
 
    # ------------------------------------------------------------------
    # UI state checks
    # ------------------------------------------------------------------
 
    def _check_visualization_type(
        self, observation: "Observation", viz_type: str
    ) -> bool:
        """
        Checks the page text/HTML for indicators that the correct
        visualization type is active.
        """
        viz_indicators: dict[str, list[str]] = {
            "bar":   ["bar chart", "bar graph", "type/bar"],
            "line":  ["line chart", "line graph", "type/line"],
            "pie":   ["pie chart", "type/pie"],
            "table": ["table", "type/table"],
            "map":   ["map", "type/map", "pin map"],
            "area":  ["area chart", "type/area"],
            "scalar":["scalar", "type/scalar", "single number"],
            "row":   ["row chart", "type/row"],
        }
        indicators = viz_indicators.get(viz_type.lower(), [viz_type.lower()])
        text = observation.text_content.lower()
        html = getattr(observation, "html_content", "").lower()
        return any(ind in text or ind in html for ind in indicators)
 
    def _check_variable_filter(
        self, observation: "Observation", traces: list["StepTrace"]
    ) -> bool:
        """
        Check that a SQL question with {{variable}} filters is active.
        Looks for the filter widget UI elements in page text/HTML.
        """
        filter_indicators = [
            "filter widget",
            "variable",
            "required widget",
            "{{",          # still in editor view
            "text filter",
            "number filter",
            "date filter",
        ]
        text = (observation.text_content + getattr(observation, "html_content", "")).lower()
        return any(ind in text for ind in filter_indicators)
 
    def _check_page_contains_chart(self, observation: "Observation") -> bool:
        """Check that a rendered chart is visible on the page."""
        chart_indicators = [
            "echarts",
            "svg",
            "<canvas",
            "highcharts",
            "chart-container",
            "dc-chart",
        ]
        html = getattr(observation, "html_content", "").lower()
        return any(ind in html for ind in chart_indicators)