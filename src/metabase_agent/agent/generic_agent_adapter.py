"""Adapter for AgentLab's GenericAgent.

This module wraps AgentLab's GenericAgent to keep the rest of the codebase
independent from AgentLab internals. When AgentLab is integrated, this adapter
will translate between our Observation/AgentAction types and AgentLab's formats.

AgentLab uses LiteLLM under the hood, which supports multiple providers:
- OpenAI: "gpt-4", "gpt-4o", "gpt-4o-mini"
- Gemini: "gemini/gemini-2.0-flash", "gemini/gemini-1.5-pro"
- Azure: "azure/deployment-name"
- OpenRouter: "openrouter/model-name"

For Gemini, set GEMINI_API_KEY in your environment.
For OpenAI, set OPENAI_API_KEY in your environment.
"""

import logging
import os
from typing import TYPE_CHECKING

from metabase_agent.agent.models import AgentAction, Observation

if TYPE_CHECKING:
    from metabase_agent.tasks.models import TaskSpec


class AgentController:
    """Controller that wraps AgentLab's GenericAgent.

    This provides a clean interface for the TaskRunner while isolating
    AgentLab-specific code. Currently implements a stub that returns
    placeholder actions - replace with actual AgentLab integration.

    Supports Gemini models via LiteLLM. Set GEMINI_API_KEY env var and use
    model names like "gemini/gemini-2.0-flash".
    """

    def __init__(
        self,
        model_name: str = "gemini/gemini-2.0-flash",
        api_key: str = "",
        base_url: str = "",
    ) -> None:
        self.model_name = model_name
        self.api_key = api_key or self._get_api_key_for_model(model_name)
        self.base_url = base_url
        self.logger = logging.getLogger(__name__)

    def _get_api_key_for_model(self, model_name: str) -> str:
        """Get the appropriate API key based on model name."""
        if model_name.startswith("gemini/"):
            return os.environ.get("GEMINI_API_KEY", "")
        elif model_name.startswith("azure/"):
            return os.environ.get("AZURE_OPENAI_API_KEY", "")
        elif model_name.startswith("openrouter/"):
            return os.environ.get("OPENROUTER_API_KEY", "")
        else:
            return os.environ.get("OPENAI_API_KEY", "")

        self._task: "TaskSpec | None" = None
        self._history: list[tuple[Observation, AgentAction]] = []

    def reset(self, task: "TaskSpec") -> None:
        """Reset the agent for a new task.

        Args:
            task: The task to execute.
        """
        self._task = task
        self._history = []
        self.logger.info(f"Agent reset for task: {task.name}")

    def act(self, observation: Observation) -> AgentAction:
        """Decide the next action based on the current observation.

        This is where AgentLab's GenericAgent would be called. Currently
        returns a placeholder action - integrate with AgentLab here.

        Args:
            observation: The current browser state.

        Returns:
            The action to execute.
        """
        if not self._task:
            raise RuntimeError("Agent not initialized. Call reset() first.")

        action = self._get_action_from_agent(observation)

        self._history.append((observation, action))

        return action

    def _get_action_from_agent(self, observation: Observation) -> AgentAction:
        """Get action from the underlying agent.

        TODO: Replace this stub with actual AgentLab GenericAgent integration.

        The integration should:
        1. Convert our Observation to AgentLab's observation format
        2. Call GenericAgent.get_action() with the task instruction and observation
        3. Parse the response into our AgentAction format
        4. Handle any errors or invalid responses

        Example integration pattern for Gemini:
        ```python
        import os
        os.environ["GEMINI_API_KEY"] = "your-key"

        from agentlab.agents.generic_agent import GenericAgentArgs
        from agentlab.llm.llm_configs import CHAT_MODEL_ARGS_DICT

        # Configure for Gemini
        model_args = CHAT_MODEL_ARGS_DICT.get("gemini-2.0-flash", {})
        agent_args = GenericAgentArgs(chat_model_args=model_args)
        agent = agent_args.make_agent()

        # Use agent in BrowserGym environment
        action = agent.get_action(bgym_obs)
        ```

        See AgentLab docs for full BrowserGym integration:
        https://github.com/ServiceNow/AgentLab
        """
        self.logger.warning(
            "Using stub agent - replace with AgentLab GenericAgent integration"
        )

        if len(self._history) >= 5:
            return AgentAction.done(reasoning="Stub agent: reached max steps")

        return AgentAction.wait(timeout=1000, reasoning="Stub agent: placeholder action")

    def get_history(self) -> list[tuple[Observation, AgentAction]]:
        """Return the history of observations and actions."""
        return self._history.copy()
