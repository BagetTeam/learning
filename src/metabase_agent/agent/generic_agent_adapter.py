"""Adapter for AgentLab's GenericAgent.

This module wraps AgentLab's GenericAgent to keep the rest of the codebase
independent from AgentLab internals. It translates between our Observation/AgentAction
types and AgentLab/BrowserGym formats.

AgentLab uses LiteLLM under the hood, which supports multiple providers:
- OpenAI: "gpt-4", "gpt-4o", "gpt-4o-mini"
- Gemini: "gemini/gemini-2.0-flash", "gemini/gemini-1.5-pro"
- Azure: "azure/deployment-name"
- OpenRouter: "openrouter/model-name"

For Gemini, set GEMINI_API_KEY in your environment.
For OpenAI, set OPENAI_API_KEY in your environment.
"""

from __future__ import annotations

import base64
import logging
import os
import re
from typing import TYPE_CHECKING, Any

from metabase_agent.agent.models import AgentAction, Observation

if TYPE_CHECKING:
    from metabase_agent.tasks.models import TaskSpec

logger = logging.getLogger(__name__)


def _get_api_key_for_model(model_name: str) -> str:
    """Get the appropriate API key based on model name."""
    if model_name.startswith("gemini/"):
        return os.environ.get("GEMINI_API_KEY", "")
    elif model_name.startswith("azure/"):
        return os.environ.get("AZURE_OPENAI_API_KEY", "")
    elif model_name.startswith("openrouter/"):
        return os.environ.get("OPENROUTER_API_KEY", "")
    else:
        return os.environ.get("OPENAI_API_KEY", "")


class AgentController:
    """Controller that wraps AgentLab's GenericAgent.

    This provides a clean interface for the TaskRunner while isolating
    AgentLab-specific code.
    """

    def __init__(
        self,
        model_name: str = "gemini/gemini-2.0-flash",
        api_key: str = "",
        base_url: str = "",
        use_vision: bool = True,
        use_html: bool = True,
        use_axtree: bool = True,
        max_tokens: int = 4096,
    ) -> None:
        self.model_name = model_name
        self.api_key = api_key or _get_api_key_for_model(model_name)
        self.base_url = base_url
        self.use_vision = use_vision
        self.use_html = use_html
        self.use_axtree = use_axtree
        self.max_tokens = max_tokens

        self._task: TaskSpec | None = None
        self._history: list[tuple[Observation, AgentAction]] = []
        self._step_count: int = 0

        self._agent: Any = None
        self._init_agent()

    def _init_agent(self) -> None:
        """Initialize the AgentLab GenericAgent."""
        try:
            from agentlab.agents.generic_agent import GenericAgentArgs
            from agentlab.llm.chat_api import ChatModelArgs

            chat_model_args = ChatModelArgs(
                model_name=self.model_name,
                max_new_tokens=self.max_tokens,
                temperature=0.1,
            )

            agent_args = GenericAgentArgs(
                chat_model_args=chat_model_args,
                flags=self._get_agent_flags(),
            )

            self._agent = agent_args.make_agent()
            logger.info(f"Initialized AgentLab GenericAgent with model: {self.model_name}")

        except ImportError as e:
            logger.warning(f"AgentLab not available, using fallback mode: {e}")
            self._agent = None
        except Exception as e:
            logger.warning(f"Failed to initialize AgentLab agent: {e}")
            self._agent = None

    def _get_agent_flags(self) -> dict[str, Any]:
        """Get agent configuration flags."""
        try:
            from agentlab.agents.generic_agent import GenericAgentArgs

            default_flags = GenericAgentArgs().flags.copy()
            default_flags.update(
                {
                    "use_html": self.use_html,
                    "use_axtree": self.use_axtree,
                    "use_screenshot": self.use_vision,
                }
            )
            return default_flags
        except ImportError:
            return {
                "use_html": self.use_html,
                "use_axtree": self.use_axtree,
                "use_screenshot": self.use_vision,
            }

    def reset(self, task: TaskSpec) -> None:
        """Reset the agent for a new task."""
        self._task = task
        self._history = []
        self._step_count = 0

        if self._agent is not None:
            try:
                self._agent.reset(goal=task.instruction)
            except Exception as e:
                logger.warning(f"Failed to reset agent: {e}")

        logger.info(f"Agent reset for task: {task.name}")

    def act(self, observation: Observation) -> AgentAction:
        """Decide the next action based on the current observation."""
        if not self._task:
            raise RuntimeError("Agent not initialized. Call reset() first.")

        self._step_count += 1

        if self._agent is not None:
            action = self._get_action_from_agentlab(observation)
        else:
            action = self._get_action_from_llm(observation)

        self._history.append((observation, action))
        return action

    def _get_action_from_agentlab(self, observation: Observation) -> AgentAction:
        """Get action using AgentLab's GenericAgent."""
        try:
            bgym_obs = self._convert_to_browsergym_obs(observation)

            agent_info = self._agent.get_action(bgym_obs)
            raw_action = agent_info.get("action", "")
            reasoning = agent_info.get("think", "")

            return self._parse_browsergym_action(raw_action, reasoning)

        except Exception as e:
            logger.warning(f"AgentLab action failed: {e}, falling back to LLM")
            return self._get_action_from_llm(observation)

    def _convert_to_browsergym_obs(self, observation: Observation) -> dict[str, Any]:
        """Convert our Observation to BrowserGym observation format."""
        obs = {
            "goal": self._task.instruction if self._task else "",
            "url": observation.url,
            "open_pages_urls": [observation.url],
            "active_page_index": 0,
            "last_action": self._get_last_action_str(),
            "last_action_error": "",
            "elapsed_time": 0.0,
            "step": self._step_count,
        }

        if self.use_html:
            obs["dom_txt"] = observation.html_snapshot[:50000]

        if self.use_axtree:
            obs["axtree_txt"] = observation.axtree if observation.axtree else self._extract_axtree(
                observation
            )

        if self.use_vision:
            screenshot_b64 = self._get_screenshot_base64(observation)
            if screenshot_b64:
                obs["screenshot"] = screenshot_b64

        return obs

    def _get_screenshot_base64(self, observation: Observation) -> str | None:
        """Get screenshot as base64 from observation."""
        if observation.screenshot_bytes:
            return base64.b64encode(observation.screenshot_bytes).decode("utf-8")

        if observation.screenshot_path:
            try:
                with open(observation.screenshot_path, "rb") as f:
                    return base64.b64encode(f.read()).decode("utf-8")
            except Exception:
                pass

        return None

    def _extract_axtree(self, observation: Observation) -> str:
        """Extract accessibility tree-like representation from the page."""
        text = observation.text_content
        lines = text.split("\n")
        axtree_lines = []
        for i, line in enumerate(lines[:200]):
            stripped = line.strip()
            if stripped:
                axtree_lines.append(f"[{i}] {stripped}")
        return "\n".join(axtree_lines)

    def _get_last_action_str(self) -> str:
        """Get string representation of last action."""
        if not self._history:
            return ""
        _, last_action = self._history[-1]
        return f"{last_action.action_type}({last_action.selector or last_action.text or ''})"

    def _parse_browsergym_action(self, raw_action: str, reasoning: str = "") -> AgentAction:
        """Parse BrowserGym action string into AgentAction."""
        raw_action = raw_action.strip()

        if not raw_action or raw_action.lower() in ["none", "noop", "done"]:
            return AgentAction.done(reasoning=reasoning)

        click_match = re.match(r'click\s*\(\s*["\']?([^"\']+)["\']?\s*\)', raw_action, re.IGNORECASE)
        if click_match:
            return AgentAction.click(click_match.group(1), reasoning=reasoning)

        fill_match = re.match(
            r'fill\s*\(\s*["\']?([^"\']+)["\']?\s*,\s*["\']([^"\']*)["\']?\s*\)',
            raw_action,
            re.IGNORECASE,
        )
        if fill_match:
            return AgentAction.type_text(fill_match.group(2), fill_match.group(1), reasoning)

        type_match = re.match(
            r'type\s*\(\s*["\']?([^"\']+)["\']?\s*,\s*["\']([^"\']*)["\']?\s*\)',
            raw_action,
            re.IGNORECASE,
        )
        if type_match:
            return AgentAction.type_text(type_match.group(2), type_match.group(1), reasoning)

        goto_match = re.match(r'goto\s*\(\s*["\']?([^"\']+)["\']?\s*\)', raw_action, re.IGNORECASE)
        if goto_match:
            return AgentAction.navigate_to(goto_match.group(1), reasoning=reasoning)

        press_match = re.match(r'press\s*\(\s*["\']?([^"\']+)["\']?\s*\)', raw_action, re.IGNORECASE)
        if press_match:
            return AgentAction.press_key(press_match.group(1), reasoning=reasoning)

        scroll_match = re.match(
            r'scroll\s*\(\s*["\']?(up|down)["\']?\s*\)', raw_action, re.IGNORECASE
        )
        if scroll_match:
            direction = scroll_match.group(1).lower()
            return AgentAction.scroll(direction=direction, reasoning=reasoning)  # type: ignore

        logger.warning(f"Could not parse action: {raw_action}")
        return AgentAction.wait(timeout=1000, reasoning=f"Unparsed: {raw_action}")

    def _get_action_from_llm(self, observation: Observation) -> AgentAction:
        """Get action directly from LLM when AgentLab is not available."""
        try:
            import litellm

            prompt = self._build_prompt(observation)

            response = litellm.completion(
                model=self.model_name,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1024,
                temperature=0.1,
            )

            response_text = response.choices[0].message.content
            return self._parse_llm_response(response_text)

        except Exception as e:
            logger.error(f"LLM call failed: {e}")
            return self._fallback_action()

    def _build_prompt(self, observation: Observation) -> str:
        """Build prompt for direct LLM call."""
        task_instruction = self._task.instruction if self._task else "Complete the task"

        prompt = f"""You are a browser automation agent. Your task is:
{task_instruction}

Current page state:
- URL: {observation.url}
- Title: {observation.title}
- Page content (truncated):
{observation.text_content[:3000]}

Previous actions taken: {len(self._history)}

Respond with exactly ONE action in this format:
- click("selector") - to click an element
- type("selector", "text") - to type text into an input
- press("key") - to press a key like Enter, Tab, Escape
- goto("url") - to navigate to a URL
- scroll("down") or scroll("up") - to scroll the page
- done() - when the task is complete

Think step by step, then provide your action.

Action:"""
        return prompt

    def _parse_llm_response(self, response: str) -> AgentAction:
        """Parse LLM response into an AgentAction."""
        lines = response.strip().split("\n")
        for line in reversed(lines):
            line = line.strip()
            if not line:
                continue

            action = self._parse_browsergym_action(line, reasoning=response[:200])
            if action.action_type != "wait":
                return action

        return self._fallback_action()

    def _fallback_action(self) -> AgentAction:
        """Return a fallback action when parsing fails."""
        if self._step_count >= 10:
            return AgentAction.done(reasoning="Fallback: max steps reached")
        return AgentAction.wait(timeout=1000, reasoning="Fallback: could not determine action")

    def get_history(self) -> list[tuple[Observation, AgentAction]]:
        """Return the history of observations and actions."""
        return self._history.copy()
