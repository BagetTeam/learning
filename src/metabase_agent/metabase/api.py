"""Metabase API client for programmatic access.

This client is used for:
- Evaluation: Verifying that objects were created/modified
- Seeding: Setting up test data programmatically
- Cleanup: Removing test artifacts
"""

import logging
from typing import Any

import httpx

logger = logging.getLogger(__name__)


class MetabaseClient:
    """HTTP client for Metabase API.

    Provides methods for common Metabase operations like
    checking dashboards, questions, and user data.
    """

    def __init__(
        self,
        base_url: str,
        username: str = "",
        password: str = "",
        session_token: str = "",
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.username = username
        self.password = password
        self._session_token = session_token
        self._client = httpx.Client(timeout=30.0)

    def authenticate(self) -> bool:
        """Authenticate with Metabase and get a session token.

        Returns:
            True if authentication was successful.
        """
        try:
            response = self._client.post(
                f"{self.base_url}/api/session",
                json={"username": self.username, "password": self.password},
            )
            response.raise_for_status()
            data = response.json()
            self._session_token = data.get("id", "")
            logger.info("API authentication successful")
            return True
        except Exception as e:
            logger.error(f"API authentication failed: {e}")
            return False

    def _headers(self) -> dict[str, str]:
        """Get headers for authenticated requests."""
        headers = {"Content-Type": "application/json"}
        if self._session_token:
            headers["X-Metabase-Session"] = self._session_token
        return headers

    def get_dashboards(self) -> list[dict[str, Any]]:
        """Get all dashboards.

        Returns:
            List of dashboard objects.
        """
        try:
            response = self._client.get(
                f"{self.base_url}/api/dashboard",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to get dashboards: {e}")
            return []

    def get_dashboard(self, dashboard_id: int) -> dict[str, Any] | None:
        """Get a specific dashboard by ID.

        Args:
            dashboard_id: The dashboard ID.

        Returns:
            Dashboard object or None if not found.
        """
        try:
            response = self._client.get(
                f"{self.base_url}/api/dashboard/{dashboard_id}",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to get dashboard {dashboard_id}: {e}")
            return None

    def get_questions(self) -> list[dict[str, Any]]:
        """Get all questions/cards.

        Returns:
            List of question objects.
        """
        try:
            response = self._client.get(
                f"{self.base_url}/api/card",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to get questions: {e}")
            return []

    def get_question(self, question_id: int) -> dict[str, Any] | None:
        """Get a specific question by ID.

        Args:
            question_id: The question ID.

        Returns:
            Question object or None if not found.
        """
        try:
            response = self._client.get(
                f"{self.base_url}/api/card/{question_id}",
                headers=self._headers(),
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to get question {question_id}: {e}")
            return None

    def question_exists(self, name: str) -> bool:
        """Check if a question with the given name exists.

        Args:
            name: Question name to search for.

        Returns:
            True if a question with that name exists.
        """
        questions = self.get_questions()
        return any(q.get("name", "").lower() == name.lower() for q in questions)

    def dashboard_exists(self, name: str) -> bool:
        """Check if a dashboard with the given name exists.

        Args:
            name: Dashboard name to search for.

        Returns:
            True if a dashboard with that name exists.
        """
        dashboards = self.get_dashboards()
        return any(d.get("name", "").lower() == name.lower() for d in dashboards)

    def close(self) -> None:
        """Close the HTTP client."""
        self._client.close()
