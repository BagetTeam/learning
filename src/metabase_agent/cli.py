"""Command-line interface for running Metabase browser agent tasks."""

import logging
import os
from pathlib import Path

import click

from metabase_agent.config import AppConfig
from metabase_agent.runner import TaskRunner
from metabase_agent.tasks.loader import load_task


def setup_logging(level: str) -> None:
    """Configure logging for the application."""
    logging.basicConfig(
        level=getattr(logging, level.upper()),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )


@click.group()
@click.version_option()
def main() -> None:
    """Metabase Browser Agent - Automate Metabase tasks."""
    pass


@main.command()
@click.option(
    "--task",
    "-t",
    required=True,
    help="Task ID or path to task YAML file.",
)
@click.option(
    "--demo",
    is_flag=True,
    default=False,
    help="Run in demo mode with visible browser.",
)
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    help="Output directory for artifacts (overrides config).",
)
@click.option(
    "--model",
    "-m",
    help="Model name to use (e.g., gemini/gemini-2.0-flash, gpt-4o).",
)
@click.option(
    "--max-steps",
    type=int,
    help="Maximum number of steps (overrides task config).",
)
def run(
    task: str,
    demo: bool,
    output: Path | None,
    model: str | None,
    max_steps: int | None,
) -> None:
    """Run a browser automation task against Metabase."""
    config = AppConfig.load()

    if demo:
        config.headless = False

    if output:
        config.artifacts_dir = output

    if model:
        config.model.name = model

    setup_logging(config.log_level)
    logger = logging.getLogger(__name__)

    logger.info(f"Loading task: {task}")
    task_spec = load_task(task)

    if max_steps:
        task_spec.max_steps = max_steps

    logger.info(f"Running task: {task_spec.name}")
    logger.info(f"Using model: {config.model.name}")
    runner = TaskRunner(config)

    result = runner.run(task_spec)

    if result.success:
        logger.info(f"Task completed successfully: {result.summary}")
        click.echo(f"Success: {result.summary}")
        click.echo(f"Steps taken: {result.total_steps}")
        click.echo(f"Time elapsed: {result.elapsed_seconds:.1f}s")
        click.echo(f"Artifacts saved to: {result.artifacts_dir}")
    else:
        logger.error(f"Task failed: {result.error}")
        click.echo(f"Failed: {result.error}", err=True)
        click.echo(f"Steps taken: {result.total_steps}")
        if result.artifacts_dir:
            click.echo(f"Artifacts saved to: {result.artifacts_dir}")
        raise SystemExit(1)


@main.command()
def list_tasks() -> None:
    """List available example tasks."""
    from metabase_agent.tasks.loader import list_example_tasks

    tasks = list_example_tasks()
    if not tasks:
        click.echo("No example tasks found.")
        return

    click.echo("Available tasks:")
    for task_id in tasks:
        click.echo(f"  - {task_id}")


@main.command()
def check() -> None:
    """Check environment setup and dependencies."""
    click.echo("Checking Metabase Agent setup...\n")

    config = AppConfig.load()

    click.echo(f"Model: {config.model.name}")

    api_key_var = None
    if config.model.name.startswith("gemini/"):
        api_key_var = "GEMINI_API_KEY"
    elif config.model.name.startswith("azure/"):
        api_key_var = "AZURE_OPENAI_API_KEY"
    elif config.model.name.startswith("openrouter/"):
        api_key_var = "OPENROUTER_API_KEY"
    else:
        api_key_var = "OPENAI_API_KEY"

    api_key = os.environ.get(api_key_var, "")
    if api_key:
        click.echo(f"API Key ({api_key_var}): Set (***{api_key[-4:]})")
    else:
        click.echo(f"API Key ({api_key_var}): NOT SET", err=True)

    click.echo(f"\nMetabase URL: {config.metabase.url}")
    click.echo(f"Metabase User: {config.metabase.username}")
    click.echo(f"Headless: {config.headless}")
    click.echo(f"Artifacts Dir: {config.artifacts_dir}")

    click.echo("\nChecking dependencies...")
    from importlib.metadata import version

    try:
        import playwright
        click.echo(f"  playwright: OK ({version('playwright')})")
    except ImportError:
        click.echo("  playwright: NOT INSTALLED", err=True)

    try:
        import agentlab
        click.echo(f"  agentlab: OK ({version('agentlab')})")
    except ImportError:
        click.echo("  agentlab: NOT INSTALLED (will use LiteLLM fallback)")

    try:
        import litellm
        click.echo(f"  litellm: OK ({version('litellm')})")
    except ImportError:
        click.echo("  litellm: NOT INSTALLED", err=True)

    click.echo("\nSetup check complete.")


if __name__ == "__main__":
    main()
