"""Task specification model."""

from dataclasses import dataclass, field


@dataclass
class TaskSpec:
    """Represents a browser automation task."""

    id: str
    name: str
    instruction: str
    start_url: str
    max_steps: int = 30
    timeout_seconds: int = 600
    success_criteria: list[str] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)
    notes: str = ""

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "id": self.id,
            "name": self.name,
            "instruction": self.instruction,
            "start_url": self.start_url,
            "max_steps": self.max_steps,
            "timeout_seconds": self.timeout_seconds,
            "success_criteria": self.success_criteria,
            "tags": self.tags,
            "notes": self.notes,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "TaskSpec":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            name=data["name"],
            instruction=data["instruction"],
            start_url=data["start_url"],
            max_steps=data.get("max_steps", 30),
            timeout_seconds=data.get("timeout_seconds", 600),
            success_criteria=data.get("success_criteria", []),
            tags=data.get("tags", []),
            notes=data.get("notes", ""),
        )
