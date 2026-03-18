"""Adapter for AgentLab's GenericAgent.

This module wraps AgentLab's GenericAgent to keep the rest of the codebase
independent from AgentLab internals. When AgentLab is integrated, this adapter
will translate between our Observation/AgentAction types and AgentLab's formats.
"""

import logging
from typing import TYPE_CHECKING

from metabase_agent.agent.models import AgentAction, Observation

if TYPE_CHECKING:
    from metabase_agent.tasks.models import TaskSpec


class AgentController:
    """Controller that wraps AgentLab's GenericAgent.

    This provides a clean interface for the TaskRunner while isolating
    AgentLab-specific code. Currently implements a stub that returns
    placeholder actions - replace with actual AgentLab integration.
    """

    def __init__(
        self,
        model_name: str = "gpt-4",
        api_key: str = "",
        base_url: str = "https://api.openai.com/v1",
    ) -> None:
        self.model_name = model_name
        self.api_key = api_key
        self.base_url = base_url
        self.logger = logging.getLogger(__name__)

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

        Example integration pattern:
        ```
        from agentlab.agents import GenericAgent

        agent = GenericAgent(
            model_name=self.model_name,
            api_key=self.api_key,
        )

        agentlab_obs = convert_to_agentlab_observation(observation, self._task)
        agentlab_action = agent.get_action(agentlab_obs)
        return convert_from_agentlab_action(agentlab_action)
        ```
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
