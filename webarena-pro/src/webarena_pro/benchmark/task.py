import logging
import tempfile
import time
from dataclasses import dataclass
import json
from typing import Any

import playwright.sync_api as pw

from browsergym.core.env import AbstractBrowserTask

from .defaults import DEPLOYED_WEBSITE_URLS, DEPLOYED_WEBSITE_LOGIN_URLS, WEBSITE_CREDENTIALS


logger = logging.getLogger(__name__)


@dataclass
class WebArenaProTaskConfig:
    task_id: str
    intent: str
    website: str
    container_name: str
    start_url: str
    evaluation: dict[str, Any] | None = None
    require_login: bool = False
    login_page: str | None = None
    startup_wait_seconds: float = 0.0
    raw_task: dict[str, Any] | None = None

    @classmethod
    def from_raw_task(cls, raw_task: dict[str, Any], container_name: str) -> "WebArenaProTaskConfig":
        website_value = raw_task.get("website")
        sites = raw_task.get("sites")
        if isinstance(sites, list) and sites:
            website_value = sites[0]

        if website_value is None:
            raise ValueError(
                "Task is missing website information. Expected non-empty `sites`."
            )

        website = str(website_value)
        start_url = DEPLOYED_WEBSITE_URLS.get(website)
        if start_url is None:
            raise ValueError(
                f"No deployed URL configured for website '{website}'. "
                f"Update webarena_pro.task.DEPLOYED_WEBSITE_URLS."
            )

        startup_wait_seconds = float(raw_task.get("startup_wait_seconds", 0.0))
        if startup_wait_seconds < 0:
            startup_wait_seconds = 0.0

        require_login = bool(raw_task.get("require_login", raw_task.get("required_login", False)))
        login_page = DEPLOYED_WEBSITE_LOGIN_URLS.get(website)
        evaluation = raw_task.get("eval", raw_task.get("evaluation"))
        if not isinstance(evaluation, dict):
            evaluation = None

        return cls(
            task_id=str(raw_task["task_id"]),
            intent=str(raw_task["intent"]),
            website=website,
            evaluation=evaluation,
            container_name=container_name,
            start_url=start_url,
            require_login=require_login,
            login_page=login_page,
            startup_wait_seconds=startup_wait_seconds,
            raw_task=dict(raw_task),
        )


class WebArenaProTask(AbstractBrowserTask):
    def __init__(self, seed: int, config: WebArenaProTaskConfig):
        super().__init__(seed=seed)
        self.config = config

    @staticmethod
    def _try_fill(page: pw.Page, selectors: list[str], value: str) -> bool:
        for selector in selectors:
            locator = page.locator(selector)
            try:
                if locator.count() > 0:
                    locator.first.fill(value)
                    return True
            except Exception:
                continue
        return False

    @staticmethod
    def _try_click(page: pw.Page, selectors: list[str]) -> bool:
        for selector in selectors:
            locator = page.locator(selector)
            try:
                if locator.count() > 0:
                    locator.first.click()
                    return True
            except Exception:
                continue
        return False

    def _ui_login(self, page: pw.Page, target_url: str) -> None:
        credentials = WEBSITE_CREDENTIALS.get(self.config.website)
        if not credentials:
            raise RuntimeError(
                f"Missing credentials for website '{self.config.website}' in webarena_pro.task.WEBSITE_CREDENTIALS"
            )

        username = credentials.get("username")
        password = credentials.get("password")
        if not username or not password:
            raise RuntimeError(
                f"Incomplete credentials for website '{self.config.website}'. Expected username/password."
            )

        login_url = self.config.login_page or target_url

        login_page = page.context.new_page()
        login_page.goto(login_url)

        user_filled = self._try_fill(
            login_page,
            [
                "#user",
                "#username",
                "input[name='user']",
                "input[name='username']",
                "input[type='email']",
            ],
            username,
        )
        password_filled = self._try_fill(
            login_page,
            [
                "#password",
                "input[name='password']",
                "input[type='password']",
            ],
            password,
        )
        submitted = self._try_click(
            login_page,
            [
                "button[type='submit']",
                "#submit-form",
                "input[type='submit']",
            ],
        )

        if not (user_filled and password_filled and submitted):
            login_page.close()
            raise RuntimeError(
                f"Could not complete login flow for website '{self.config.website}' at '{login_url}'."
            )

        login_page.close()

    def setup(self, page: pw.Page):
        if self.config.startup_wait_seconds > 0:
            time.sleep(self.config.startup_wait_seconds)

        target_url = self.config.start_url
        if not target_url:
            raise RuntimeError(
                f"Could not resolve start URL for website '{self.config.website}'."
            )

        if self.config.require_login:
            self._ui_login(page=page, target_url=target_url)

        info = {
            "task_id": self.config.task_id,
            "website": self.config.website,
            "start_url": target_url,
        }
        page.goto(target_url)
        return self.config.intent, info

    def validate(
        self,
        page: pw.Page,
        chat_messages,
        last_step_output: Any | None = None,
        **_: Any,
    ):
        reward = 0.0 # TODO: call evaluation function based on self.config.evaluation and the current state of the page, chat messages, and last step output
        done = False
        user_message = ""
        info = {}
        return reward, done, user_message, info

    def cheat(self, page: pw.Page, chat_messages):
        raise NotImplementedError

    def teardown(self):
        return
