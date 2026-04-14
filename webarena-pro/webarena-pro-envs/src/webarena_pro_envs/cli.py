"""WebArena-Pro CLI. This module provides command-line interface for managing WebArena-Pro environments and containers.

usage:
    webarena-pro env list
    webarena-pro env help [subcommand]
    webarena-pro env pull <env_name|all>
    webarena-pro env start <env_name|all>
    webarena-pro env stop <env_name|all>
    webarena-pro env restart <env_name|all>
    webarena-pro env status <env_name>
    webarena-pro serve [--host <host>] [--port <port>]
    webarena-pro help [topic...]
"""

from __future__ import annotations

import argparse
import time
from typing import Iterable

import docker

from . import WEBSITES_CONTAINER_PORTS, WEBSITES_HOST_PORTS, WEBSITES_IMAGES
from .dashboard_server import start_dashboard_server
from .docker import DockerContainerManager


def _add_common_name_argument(parser: argparse.ArgumentParser, *, help: str) -> None:
    parser.add_argument(
        "name",
        metavar="NAME",
        help=help,
    )


def _iter_known_envs() -> Iterable[tuple[str, str]]:
    """Yield (name, image) pairs for all known environments."""
    for name, image in WEBSITES_IMAGES.items():
        yield str(name), str(image)


def _iter_target_envs(name: str) -> list[tuple[str, str]]:
    if name == "all":
        return list(_iter_known_envs())
    image = _resolve_image(name)
    return [(name, image)]


def _resolve_image(name: str) -> str:
    try:
        return WEBSITES_IMAGES[name]
    except KeyError as error:
        known = ", ".join(sorted(WEBSITES_IMAGES)) or "<none>"
        msg = f"Unknown environment '{name}'. Known environments: {known}"
        raise SystemExit(msg) from error


def _resolve_container_port(name: str) -> int:
    return int(WEBSITES_CONTAINER_PORTS.get(name, 80))


def _resolve_host_port(name: str) -> int:
    try:
        return int(WEBSITES_HOST_PORTS[name])
    except KeyError as error:
        known = ", ".join(sorted(WEBSITES_HOST_PORTS)) or "<none>"
        msg = f"No fixed host port configured for '{name}'. Configured environments: {known}"
        raise SystemExit(msg) from error


def _build_ports(name: str) -> dict[str, int]:
    container_port = _resolve_container_port(name)
    host_port = _resolve_host_port(name)
    return {f"{container_port}/tcp": host_port}


def _preferred_ports(name: str) -> list[str]:
    ports = [str(_resolve_container_port(name)), "80"]
    deduplicated: list[str] = []
    for port in ports:
        if port not in deduplicated:
            deduplicated.append(port)
    return deduplicated


def cmd_list(_: argparse.Namespace) -> int:
    print("Available WebArena-Pro environments:")
    if not WEBSITES_IMAGES:
        print("  (none configured)")
        return 0

    for name, image in _iter_known_envs():
        container_port = _resolve_container_port(name)
        host_port = _resolve_host_port(name)
        print(
            f"  - {name}: {image} (container port {container_port} -> host port {host_port})"
        )
    return 0


def cmd_pull(args: argparse.Namespace) -> int:
    client = docker.from_env()
    if args.name == "all":
        to_pull = list(_iter_known_envs())
    else:
        image = _resolve_image(args.name)
        to_pull = [(args.name, image)]

    if not to_pull:
        print("Nothing to pull.")
        return 0

    for name, image in to_pull:
        print(f"Pulling image for '{name}': {image} ...", flush=True)
        client.images.pull(image)
        print(f"  ✓ Pulled {image}")

    return 0


def cmd_start(args: argparse.Namespace) -> int:
    manager = DockerContainerManager()
    targets = _iter_target_envs(args.name)
    if not targets:
        print("Nothing to start.")
        return 0

    for name, image in targets:
        ports = _build_ports(name)
        info = manager.ensure_container_running(
            name=name,
            image=image,
            ports=ports,
        )
        url = manager.get_container_url(
            name=name,
            preferred_container_ports=_preferred_ports(name),
        )

        print(f"Container '{info.name}' is {info.status} (health: {info.health})")
        if url:
            print(f"URL: {url}")

    if args.name == "all":
        print("All environment containers started. Waiting 60 seconds for readiness...", flush=True)
        time.sleep(60)
        print("All environment containers are ready.")

    return 0


def cmd_stop(args: argparse.Namespace) -> int:
    manager = DockerContainerManager()
    targets = _iter_target_envs(args.name)
    if not targets:
        print("Nothing to stop.")
        return 0

    for name, _ in targets:
        manager.stop_container(name)
        print(f"Stopped container '{name}' (if it existed).")
    return 0


def cmd_restart(args: argparse.Namespace) -> int:
    manager = DockerContainerManager()
    targets = _iter_target_envs(args.name)
    if not targets:
        print("Nothing to restart.")
        return 0

    for name, image in targets:
        ports = _build_ports(name)
        info = manager.reset_container(
            name=name,
            image=image,
            ports=ports,
        )
        url = manager.get_container_url(
            name=name,
            preferred_container_ports=_preferred_ports(name),
        )

        print(f"Restarted container '{info.name}' -> {info.status} (health: {info.health})")
        if url:
            print(f"URL: {url}")

    return 0


def cmd_status(args: argparse.Namespace) -> int:
    manager = DockerContainerManager()
    try:
        info = manager.get_container_info(args.name)
    except docker.errors.NotFound:
        print(f"No container found with name '{args.name}'.")
        return 1

    url = manager.get_container_url(
        name=args.name,
        preferred_container_ports=_preferred_ports(args.name),
    )

    print(f"Name:    {info.name}")
    print(f"Status:  {info.status}")
    print(f"Health:  {info.health}")
    if url:
        print(f"URL:     {url}")

    return 0


def cmd_serve(args: argparse.Namespace) -> int:
    start_dashboard_server(host=args.host, port=args.port)
    return 0


def cmd_help(args: argparse.Namespace) -> int:
    topic_tokens = [str(token).strip() for token in args.topic if str(token).strip()]
    topic_key = " ".join(topic_tokens)

    if not topic_key:
        args.parser.print_help()
        return 0

    target_parser = args.help_targets.get(topic_key)
    if target_parser is None:
        available = ", ".join(sorted(args.help_targets))
        print(f"Unknown help topic '{topic_key}'. Available topics: {available}")
        return 1

    target_parser.print_help()
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="webarena-pro",
        description="CLI to manage WebArena-Pro Docker environments.",
    )

    subparsers = parser.add_subparsers(
        title="commands",
        dest="command",
        required=True,
    )

    p_env = subparsers.add_parser(
        "env",
        help="Manage WebArena-Pro environments.",
    )
    env_subparsers = p_env.add_subparsers(
        title="env commands",
        dest="env_command",
        required=True,
    )

    # list
    p_list = env_subparsers.add_parser(
        "list",
        help="List known WebArena-Pro environments.",
    )
    p_list.set_defaults(func=cmd_list)

    # pull
    p_pull = env_subparsers.add_parser(
        "pull",
        help="Pull Docker images for environments.",
    )
    p_pull.add_argument(
        "name",
        metavar="NAME|all",
        help="Environment name to pull, or 'all' for every known environment.",
    )
    p_pull.set_defaults(func=cmd_pull)

    # start
    p_start = env_subparsers.add_parser(
        "start",
        help="Start (or create) a container for an environment.",
    )
    p_start.add_argument(
        "name",
        metavar="NAME|all",
        help="Environment name to start, or 'all' for every known environment.",
    )
    p_start.set_defaults(func=cmd_start)

    # stop
    p_stop = env_subparsers.add_parser(
        "stop",
        help="Stop and remove the container for an environment.",
    )
    p_stop.add_argument(
        "name",
        metavar="NAME|all",
        help="Environment name to stop, or 'all' for every known environment.",
    )
    p_stop.set_defaults(func=cmd_stop)

    # restart
    p_restart = env_subparsers.add_parser(
        "restart",
        help="Reset the container for an environment (stop + start).",
    )
    p_restart.add_argument(
        "name",
        metavar="NAME|all",
        help="Environment name to restart, or 'all' for every known environment.",
    )
    p_restart.set_defaults(func=cmd_restart)

    # status
    p_status = env_subparsers.add_parser(
        "status",
        help="Show status and URL for an environment container.",
    )
    _add_common_name_argument(p_status, help="Environment name to inspect.")
    p_status.set_defaults(func=cmd_status)

    p_env_help = env_subparsers.add_parser(
        "help",
        help="Show help for env commands.",
    )
    p_env_help.add_argument(
        "topic",
        nargs="*",
        metavar="TOPIC",
        help="Optional env command name, e.g. 'list' or 'start'.",
    )
    p_env_help.set_defaults(
        func=cmd_help,
        parser=p_env,
        help_targets={
            "list": p_list,
            "pull": p_pull,
            "start": p_start,
            "stop": p_stop,
            "restart": p_restart,
            "status": p_status,
            "help": p_env_help,
        },
    )

    # serve
    p_serve = subparsers.add_parser(
        "serve",
        help="Run a local dashboard to manage and open environments.",
    )
    p_serve.add_argument(
        "--host",
        default="127.0.0.1",
        help="Host interface to bind the dashboard server.",
    )
    p_serve.add_argument(
        "--port",
        type=int,
        default=8080,
        help="Port to bind the dashboard server.",
    )
    p_serve.set_defaults(func=cmd_serve)

    p_help = subparsers.add_parser(
        "help",
        help="Show help for commands.",
    )
    p_help.add_argument(
        "topic",
        nargs="*",
        metavar="TOPIC",
        help="Optional command path, e.g. 'env', 'env list', or 'serve'.",
    )
    p_help.set_defaults(
        func=cmd_help,
        parser=parser,
        help_targets={
            "env": p_env,
            "env list": p_list,
            "env pull": p_pull,
            "env start": p_start,
            "env stop": p_stop,
            "env restart": p_restart,
            "env status": p_status,
            "env help": p_env_help,
            "serve": p_serve,
            "help": p_help,
        },
    )

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    func = getattr(args, "func", None)
    if func is None:
        parser.print_help()
        return 1
    return int(func(args))


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())

