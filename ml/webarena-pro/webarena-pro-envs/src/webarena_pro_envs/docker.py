from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import docker
from docker.errors import NotFound


@dataclass
class ContainerInfo:
	name: str
	status: str
	health: str = "unknown"


class DockerContainerManager:
	def __init__(self) -> None:
		self.client = docker.from_env()

	@staticmethod
	def _normalize_container_port(port: str) -> str:
		return port if "/" in port else f"{port}/tcp"

	def _to_container_info(self, container: Any) -> ContainerInfo:
		container.reload()
		state = (container.attrs or {}).get("State", {})
		health_state = state.get("Health", {})
		health_status = health_state.get("Status", "unknown")
		return ContainerInfo(
			name=container.name,
			status=container.status,
			health=health_status,
		)

	def get_container_info(self, name: str) -> ContainerInfo:
		container = self.client.containers.get(name)
		return self._to_container_info(container)

	def list_containers(self) -> list[ContainerInfo]:
		containers = self.client.containers.list(all=True)
		return [self._to_container_info(container) for container in containers]

	def ensure_container_running(
		self,
		*,
		name: str,
		image: str,
		environment: dict[str, str] | None = None,
		ports: dict[str, int] | None = None,
	) -> ContainerInfo:
		try:
			container = self.client.containers.get(name)
			if container.status != "running":
				container.start()
			return self._to_container_info(container)
		except NotFound:
			container = self.client.containers.run(
				image=image,
				name=name,
				detach=True,
				environment=environment,
				ports=ports,
			)
			return self._to_container_info(container)

	def reset_container(
		self,
		*,
		name: str,
		image: str,
		environment: dict[str, str] | None = None,
		ports: dict[str, int] | None = None,
	) -> ContainerInfo:
		self.stop_container(name)
		container = self.client.containers.run(
			image=image,
			name=name,
			detach=True,
			environment=environment,
			ports=ports,
		)
		return self._to_container_info(container)

	def stop_container(self, name: str) -> None:
		try:
			container = self.client.containers.get(name)
		except NotFound:
			return
		container.remove(force=True)

	def health_check(self, name: str) -> dict[str, str]:
		info = self.get_container_info(name)
		return {
			"name": info.name,
			"status": info.status,
			"health": info.health,
		}

	def get_container_url(
		self,
		*,
		name: str,
		preferred_container_ports: list[str] | None = None,
		host: str = "localhost",
		scheme: str = "http",
	) -> str | None:
		container = self.client.containers.get(name)
		container.reload()
		ports = (container.attrs or {}).get("NetworkSettings", {}).get("Ports", {}) or {}
		if not isinstance(ports, dict) or not ports:
			return None

		ordered_port_keys: list[str] = []
		if preferred_container_ports:
			ordered_port_keys.extend(
				self._normalize_container_port(port)
				for port in preferred_container_ports
			)
		ordered_port_keys.extend(str(port_key) for port_key in ports.keys())

		seen: set[str] = set()
		for port_key in ordered_port_keys:
			if port_key in seen:
				continue
			seen.add(port_key)
			bindings = ports.get(port_key)
			if not isinstance(bindings, list) or not bindings:
				continue
			host_port = bindings[0].get("HostPort")
			if not host_port:
				continue
			return f"{scheme}://{host}:{host_port}"

		return None
