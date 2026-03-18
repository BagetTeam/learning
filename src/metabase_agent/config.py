"""Application configuration loaded from environment variables."""

from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class MetabaseConfig(BaseSettings):
    """Metabase connection settings."""

    model_config = SettingsConfigDict(env_prefix="METABASE_")

    url: str = "http://localhost:3000"
    username: str = "agent@example.com"
    password: str = "changeme"


class ModelConfig(BaseSettings):
    """LLM model settings for the agent."""

    model_config = SettingsConfigDict(env_prefix="MODEL_")

    name: str = "gpt-4"
    api_key: str = ""
    base_url: str = "https://api.openai.com/v1"


class AppConfig(BaseSettings):
    """Main application configuration."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    metabase: MetabaseConfig = Field(default_factory=MetabaseConfig)
    model: ModelConfig = Field(default_factory=ModelConfig)

    headless: bool = True
    artifacts_dir: Path = Path("./runs")
    log_level: str = "INFO"

    @classmethod
    def load(cls) -> "AppConfig":
        """Load configuration from environment."""
        return cls(
            metabase=MetabaseConfig(),
            model=ModelConfig(),
        )
