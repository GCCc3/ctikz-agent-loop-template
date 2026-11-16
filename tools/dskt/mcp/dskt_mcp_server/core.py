"""Shared path, HTTP, envelope, and trace helpers for the Dskt MCP shim."""

from __future__ import annotations

import json
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import quote

import httpx

SCHEMA_VERSION = 1
TOOL_VERSION = "0.2.0"


class ShimError(Exception):
    """A client-side error returned in the MCP envelope."""

    def __init__(self, code: str, message: str, details: dict[str, Any] | None = None):
        super().__init__(message)
        self.code = code
        self.message = message
        self.details = details or {}


def repo_root() -> Path:
    return Path(os.environ.get("DSKT_REPO_ROOT", ".")).resolve()


def output_root() -> Path:
    configured = os.environ.get("PNG_OUTPUT_ROOT")
    return Path(configured).resolve() if configured else repo_root() / "tmp" / "png-measure"


def trace_log() -> Path:
    configured = os.environ.get("DSKT_TRACE_LOG")
    if configured:
        path = Path(configured)
        return path.resolve() if path.is_absolute() else (repo_root() / path).resolve()
    return repo_root() / "tmp" / "dskt" / "tool-trace.jsonl"


def service_url(path: str) -> str:
    host = os.environ.get("DSKT_HOST", "127.0.0.1")
    port = os.environ.get("DSKT_PORT", "8087")
    return f"http://{host}:{port}{path}"


def resolve_image_path(image_path: str) -> tuple[str, str]:
    root = repo_root()
    candidate = Path(image_path)
    resolved = candidate.resolve() if candidate.is_absolute() else (root / candidate).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ShimError("path_outside_repo", f"Image path escapes the repository root: {image_path}") from exc
    if not resolved.is_file():
        raise ShimError("image_not_found", f"Image does not exist: {image_path}")
    return str(resolved), str(resolved.relative_to(root))


def _request_id() -> str:
    return str(uuid.uuid4())


_CLIENT_ID = str(uuid.uuid4())


def _headers(request_id: str) -> dict[str, str]:
    headers = {
        "Content-Type": "application/json",
        "X-DSKT-Request-Id": request_id,
        "X-DSKT-Client-Id": _CLIENT_ID,
    }
    role = os.environ.get("DSKT_CLIENT_ROLE", "").strip()
    if role:
        headers["X-DSKT-Client-Role"] = role
    return headers


def _trace_line(
    *,
    request_id: str,
    tool: str,
    outcome: str,
    error_code: str | None,
    details: dict[str, Any] | None = None,
) -> None:
    """Best-effort shim trace line for rejected or failed calls."""
    try:
        path = trace_log()
        path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "schema_version": SCHEMA_VERSION,
            "run_id": _CLIENT_ID,
            "sequence": 0,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "phase": "mcp",
            "request_id": request_id,
            "client_id": _CLIENT_ID,
            "client_role": os.environ.get("DSKT_CLIENT_ROLE", "unknown") or "unknown",
            "tool": tool,
            "outcome": outcome,
            "error_code": error_code,
            "warning_codes": [],
            "duration_ms": 0,
            "result_bytes": 0,
            "tool_family": (details or {}).get("tool_family"),
            "snippet_id": (details or {}).get("snippet_id"),
            "source_path": (details or {}).get("source_path"),
            "check_counts": (details or {}).get("check_counts"),
            "catalog_version": (details or {}).get("catalog_version"),
            "lint_rules_version": (details or {}).get("lint_rules_version"),
            "details": details or {},
        }
        line = json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n"
        fd = os.open(path, os.O_APPEND | os.O_CREAT | os.O_WRONLY, 0o644)
        try:
            os.write(fd, line.encode("utf-8"))
        finally:
            os.close(fd)
    except Exception:
        # Trace failures never change the tool result.
        pass


def envelope_success(result: dict[str, Any]) -> dict[str, Any]:
    return {
        "success": True,
        "schema_version": SCHEMA_VERSION,
        "tool_version": TOOL_VERSION,
        "result": result,
    }


def envelope_error(error: ShimError | Exception) -> dict[str, Any]:
    if isinstance(error, ShimError):
        code, message, details = error.code, error.message, error.details
    else:
        code, message, details = "internal_error", str(error) or error.__class__.__name__, {}
    return {
        "success": False,
        "schema_version": SCHEMA_VERSION,
        "tool_version": TOOL_VERSION,
        "error": {"code": code, "message": message, "details": details},
    }


def _decode(response: httpx.Response) -> dict[str, Any]:
    try:
        body = response.json()
    except ValueError as exc:
        raise ShimError(
            "internal_error",
            f"Dskt service returned non-JSON HTTP {response.status_code}",
        ) from exc
    if not isinstance(body, dict):
        raise ShimError("internal_error", "Dskt service returned a non-object JSON body")
    return body


def get_json(path: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    request_id = _request_id()
    try:
        response = httpx.get(service_url(path), params=params or {}, headers=_headers(request_id), timeout=30.0)
        return _decode(response)
    except ShimError as exc:
        _trace_line(request_id=request_id, tool=path, outcome="rejected", error_code=exc.code, details={"path": path})
        return envelope_error(exc)
    except httpx.HTTPError as exc:
        error = ShimError("transport_error", f"Cannot reach the Dskt service: {exc}")
        _trace_line(request_id=request_id, tool=path, outcome="error", error_code=error.code, details={"path": path})
        return envelope_error(error)


def post_json(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    request_id = _request_id()
    try:
        response = httpx.post(service_url(path), json=payload, headers=_headers(request_id), timeout=120.0)
        return _decode(response)
    except ShimError as exc:
        _trace_line(request_id=request_id, tool=path, outcome="rejected", error_code=exc.code, details={"path": path})
        return envelope_error(exc)
    except httpx.HTTPError as exc:
        error = ShimError("transport_error", f"Cannot reach the Dskt service: {exc}")
        _trace_line(request_id=request_id, tool=path, outcome="error", error_code=error.code, details={"path": path})
        return envelope_error(error)


def png_payload(
    image_path: str,
    *,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    absolute, relative = resolve_image_path(image_path)
    payload: dict[str, Any] = {
        "image_path": relative,
        "image_abs_path": absolute,
        "output_root": str(output_root()),
    }
    if mask is not None:
        payload["mask"] = mask
    if dpi_override is not None:
        payload["dpi_override"] = dpi_override
    return payload


def snippet_path(snippet_id: str) -> str:
    return "/ctikz/snippets/" + quote(snippet_id, safe="/")
