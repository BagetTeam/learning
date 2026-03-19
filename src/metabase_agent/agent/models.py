"""Agent observation and action models."""

from dataclasses import dataclass, field
from typing import Literal


@dataclass
class Observation:
    """Represents what the agent observes from the browser.

    This captures the current state of the page for the agent to make decisions.
    """

    url: str
    title: str
    text_content: str
    html_snapshot: str
    screenshot_path: str | None = None
    screenshot_bytes: bytes | None = None
    axtree: str = ""
    metadata: dict = field(default_factory=dict)

    def summary(self) -> str:
        """Return a brief summary of the observation."""
        return f"URL: {self.url}, Title: {self.title}, Content length: {len(self.text_content)}"

    def has_screenshot(self) -> bool:
        """Check if screenshot is available."""
        return self.screenshot_bytes is not None or self.screenshot_path is not None


ActionType = Literal["click", "type", "press", "navigate", "scroll", "select", "wait", "done"]


@dataclass
class AgentAction:
    """Represents an action the agent wants to execute.

    Different action types use different fields:
    - click: selector or coordinates
    - type: selector (optional) + text
    - press: key
    - navigate: url
    - scroll: direction + amount
    - select: selector + value
    - wait: timeout
    - done: signals task completion
    """

    action_type: ActionType
    selector: str | None = None
    text: str | None = None
    key: str | None = None
    url: str | None = None
    coordinates: tuple[int, int] | None = None
    direction: Literal["up", "down", "left", "right"] | None = None
    amount: int | None = None
    value: str | None = None
    timeout: int | None = None
    reasoning: str = ""

    @classmethod
    def click(cls, selector: str, reasoning: str = "") -> "AgentAction":
        """Create a click action."""
        return cls(action_type="click", selector=selector, reasoning=reasoning)

    @classmethod
    def type_text(cls, text: str, selector: str | None = None, reasoning: str = "") -> "AgentAction":
        """Create a type action."""
        return cls(action_type="type", selector=selector, text=text, reasoning=reasoning)

    @classmethod
    def press_key(cls, key: str, reasoning: str = "") -> "AgentAction":
        """Create a key press action."""
        return cls(action_type="press", key=key, reasoning=reasoning)

    @classmethod
    def navigate_to(cls, url: str, reasoning: str = "") -> "AgentAction":
        """Create a navigation action."""
        return cls(action_type="navigate", url=url, reasoning=reasoning)

    @classmethod
    def scroll(
        cls,
        direction: Literal["up", "down"] = "down",
        amount: int = 300,
        reasoning: str = "",
    ) -> "AgentAction":
        """Create a scroll action."""
        return cls(action_type="scroll", direction=direction, amount=amount, reasoning=reasoning)

    @classmethod
    def select_option(cls, selector: str, value: str, reasoning: str = "") -> "AgentAction":
        """Create a select action."""
        return cls(action_type="select", selector=selector, value=value, reasoning=reasoning)

    @classmethod
    def wait(cls, timeout: int = 1000, reasoning: str = "") -> "AgentAction":
        """Create a wait action."""
        return cls(action_type="wait", timeout=timeout, reasoning=reasoning)

    @classmethod
    def done(cls, reasoning: str = "") -> "AgentAction":
        """Signal that the task is complete."""
        return cls(action_type="done", reasoning=reasoning)

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "action_type": self.action_type,
            "selector": self.selector,
            "text": self.text,
            "key": self.key,
            "url": self.url,
            "coordinates": self.coordinates,
            "direction": self.direction,
            "amount": self.amount,
            "value": self.value,
            "timeout": self.timeout,
            "reasoning": self.reasoning,
        }
