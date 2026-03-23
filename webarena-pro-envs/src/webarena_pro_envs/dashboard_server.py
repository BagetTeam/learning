from __future__ import annotations

import json
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

from docker.errors import NotFound

from . import WEBSITES_CONTAINER_PORTS, WEBSITES_HOST_PORTS, WEBSITES_IMAGES
from .docker import DockerContainerManager

_DASHBOARD_HTML_PATH = Path(__file__).parent / "static" / "index.html"


def _resolve_container_port(name: str) -> int:
    return int(WEBSITES_CONTAINER_PORTS.get(name, 80))


def _resolve_host_port(name: str) -> int:
    return int(WEBSITES_HOST_PORTS[name])


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


def _collect_environments(manager: DockerContainerManager) -> list[dict[str, str | bool | None]]:
    environments: list[dict[str, str | bool | None]] = []

    for name, image in WEBSITES_IMAGES.items():
        entry: dict[str, str | bool | None] = {
            "name": str(name),
            "image": str(image),
            "status": "not-created",
            "health": "unknown",
            "url": None,
            "running": False,
        }
        try:
            info = manager.get_container_info(str(name))
            entry["status"] = info.status
            entry["health"] = info.health
            entry["running"] = info.status == "running"
            entry["url"] = manager.get_container_url(
                name=str(name),
                preferred_container_ports=_preferred_ports(str(name)),
            )
        except NotFound:
            pass
        except Exception as error:  # pragma: no cover - defensive API reporting
            entry["status"] = "error"
            entry["health"] = str(error)
        environments.append(entry)

    return environments


class DashboardRequestHandler(BaseHTTPRequestHandler):
    manager = DockerContainerManager()

    def _send_json(self, payload: dict | list, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(int(status))
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_html(self, html: str, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = html.encode("utf-8")
        self.send_response(int(status))
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _split_api_path(self, path: str) -> list[str]:
        return [part for part in path.strip("/").split("/") if part]

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path in {"/", "/index.html"}:
            self._send_html(_DASHBOARD_HTML_PATH.read_text(encoding="utf-8"))
            return

        if parsed.path == "/api/environments":
            environments = _collect_environments(self.manager)
            self._send_json({"environments": environments})
            return

        self._send_json({"error": "Not found"}, status=HTTPStatus.NOT_FOUND)

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        parts = self._split_api_path(parsed.path)

        if len(parts) != 4 or parts[:2] != ["api", "environments"]:
            self._send_json({"error": "Not found"}, status=HTTPStatus.NOT_FOUND)
            return

        name = parts[2]
        action = parts[3]

        if name not in WEBSITES_IMAGES:
            self._send_json(
                {"error": f"Unknown environment '{name}'."},
                status=HTTPStatus.BAD_REQUEST,
            )
            return

        try:
            image = WEBSITES_IMAGES[name]

            if action == "start":
                self.manager.ensure_container_running(
                    name=name,
                    image=image,
                    ports=_build_ports(name),
                )
            elif action == "restart":
                self.manager.reset_container(
                    name=name,
                    image=image,
                    ports=_build_ports(name),
                )
            elif action == "stop":
                self.manager.stop_container(name)
            else:
                self._send_json(
                    {"error": f"Unsupported action '{action}'."},
                    status=HTTPStatus.BAD_REQUEST,
                )
                return
        except ValueError as error:
            self._send_json({"error": str(error)}, status=HTTPStatus.BAD_REQUEST)
            return
        except Exception as error:  # pragma: no cover - runtime docker errors
            self._send_json({"error": str(error)}, status=HTTPStatus.INTERNAL_SERVER_ERROR)
            return

        environments = _collect_environments(self.manager)
        self._send_json({"environments": environments}, status=HTTPStatus.OK)


def start_dashboard_server(*, host: str = "127.0.0.1", port: int = 8080) -> None:
    server = ThreadingHTTPServer((host, port), DashboardRequestHandler)
    print(f"Dashboard available at http://{host}:{port}")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping dashboard...")
    finally:
        server.server_close()
