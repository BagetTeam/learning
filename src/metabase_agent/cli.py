"""Command-line interface for running Metabase browser agent tasks."""

import logging
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
def run(task: str, demo: bool, output: Path | None) -> None:
    """Run a browser automation task against Metabase."""
    config = AppConfig.load()

    if demo:
        config.headless = False

    if output:
        config.artifacts_dir = output

    setup_logging(config.log_level)
    logger = logging.getLogger(__name__)

    logger.info(f"Loading task: {task}")
    task_spec = load_task(task)

    logger.info(f"Running task: {task_spec.name}")
    runner = TaskRunner(config)

    result = runner.run(task_spec)

    if result.success:
        logger.info(f"Task completed successfully: {result.summary}")
        click.echo(f"Success: {result.summary}")
        click.echo(f"Artifacts saved to: {result.artifacts_dir}")
    else:
        logger.error(f"Task failed: {result.error}")
        click.echo(f"Failed: {result.error}", err=True)
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


if __name__ == "__main__":
    main()
