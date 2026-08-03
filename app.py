#!/usr/bin/env python3
"""Tiny dependency-free HTTP app for Docker troubleshooting practice."""

from __future__ import annotations

import json
import os
import subprocess
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit


REQUIRED_ENV = ("APP_SECRET", "DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD")


def database_query() -> tuple[bool, str]:
    env = os.environ.copy()
    env["PGPASSWORD"] = env["DB_PASSWORD"]
    command = [
        "psql",
        "-h",
        env["DB_HOST"],
        "-p",
        env["DB_PORT"],
        "-U",
        env["DB_USER"],
        "-d",
        env["DB_NAME"],
        "-Atqc",
        "SELECT 10;",
    ]
    try:
        result = subprocess.run(
            command,
            env=env,
            capture_output=True,
            text=True,
            timeout=3,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return False, "database connection timed out"
    except OSError:
        return False, "database client could not be started"

    if result.returncode != 0:
        error = (
            result.stderr.strip().splitlines()[-1]
            if result.stderr.strip()
            else "database query failed"
        )
        return False, error
    return True, result.stdout.strip()


class Handler(BaseHTTPRequestHandler):
    server_version = "DockerTSELab/1.0"

    def setup(self) -> None:
        super().setup()
        self.connection.settimeout(5)

    def do_GET(self) -> None:  # noqa: N802 - required by BaseHTTPRequestHandler
        path = urlsplit(self.path).path
        if path not in {"/health", "/customers"}:
            self.respond(HTTPStatus.NOT_FOUND, {"error": "route_not_found"})
            return

        connected, detail = database_query()
        if not connected:
            print(
                f"level=error event=database_connection_failed detail={detail!r}",
                flush=True,
            )
            self.respond(
                HTTPStatus.SERVICE_UNAVAILABLE,
                {"status": "unavailable", "error": "database_connection_failed"},
            )
            return

        if path == "/health":
            self.respond(HTTPStatus.OK, {"status": "healthy", "database": "connected"})
        else:
            self.respond(HTTPStatus.OK, {"status": "ok", "customer_count": int(detail)})

    def respond(self, status: HTTPStatus, body: dict[str, object]) -> None:
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format: str, *args: object) -> None:
        print(
            f"level=info client={self.client_address[0]} message={format % args}",
            flush=True,
        )


def main() -> None:
    missing = [name for name in REQUIRED_ENV if not os.environ.get(name)]
    if missing:
        raise SystemExit(
            f"ERROR: required environment variable {missing[0]} is not set"
        )

    server = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
    server.daemon_threads = True
    print("level=info event=server_started port=8080", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
