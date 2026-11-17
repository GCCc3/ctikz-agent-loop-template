"""FastMCP tools for the shared Dskt Pharo service."""

from __future__ import annotations

import os
from typing import Annotated, Any

from fastmcp import FastMCP
from pydantic import Field

from .core import (
    ShimError,
    envelope_error,
    get_json,
    png_payload,
    post_json,
    snippet_path,
)

mcp = FastMCP(
    "dskt",
    instructions=(
        "Measure PNG geometry and inspect or render CircuitTikZ snippets through one "
        "Pharo DsktServer. Use typed tools; do not infer visual fidelity from lint."
    ),
)

READONLY = {"readOnlyHint": True}
WRITE = {"readOnlyHint": False, "destructiveHint": False, "idempotentHint": True, "openWorldHint": False}


# --- PNG domain ---------------------------------------------------------


def _png(
    tool: str,
    image_path: str,
    *,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    try:
        payload = png_payload(image_path, mask=mask, dpi_override=dpi_override)
        if extra:
            payload.update(extra)
        return post_json(f"/png/{tool}", payload)
    except ShimError as error:
        return envelope_error(error)


def png_inspect_image(
    image_path: str,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Inspect a PNG and report dimensions, colour type, alpha, and resolution."""
    return _png("inspect_image", image_path, mask=mask, dpi_override=dpi_override)


def png_make_ink_mask(
    image_path: str,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Create a deterministic binary ink-mask PNG under the configured output root."""
    return _png("make_ink_mask", image_path, mask=mask, dpi_override=dpi_override)


def png_measure_bounds(
    image_path: str,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Measure the canvas, ink bounds, margins, aspect ratios, and tight-crop status."""
    return _png("measure_bounds", image_path, mask=mask, dpi_override=dpi_override)


def png_measure_regions(
    image_path: str,
    regions: dict[str, list[float]],
    region_units: str = "normalized_ink",
    mask: dict[str, Any] | None = None,
    image_sha256: str | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Measure aggregate ink inside named windows and return tightened geometry."""
    if not isinstance(regions, dict) or not regions:
        return envelope_error(ShimError("invalid_request", "regions must be a non-empty object"))
    if region_units not in {"normalized_ink", "normalized_image", "image_pixels"}:
        return envelope_error(ShimError("unknown_basis", f"Unsupported region_units: {region_units}"))
    extra: dict[str, Any] = {"regions": regions, "region_units": region_units}
    if image_sha256 is not None:
        extra["image_sha256"] = image_sha256
    return _png("measure_regions", image_path, mask=mask, dpi_override=dpi_override, extra=extra)


def png_normalize_geometry(
    image_path: str,
    geometry: dict[str, Any],
    from_basis: Annotated[str, Field(alias="from")],
    to_basis: Annotated[str, Field(alias="to")],
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Convert a point or box between image, ink, normalized, and centimetre bases."""
    return _png(
        "normalize_geometry",
        image_path,
        mask=mask,
        dpi_override=dpi_override,
        extra={"geometry": geometry, "from": from_basis, "to": to_basis},
    )


def png_health() -> dict[str, Any]:
    """Report PNG measurement health and cache status."""
    return get_json("/png/health")


def png_trace(
    limit: int = 50,
    since_sequence: int | None = None,
    tool: str | None = None,
    client_id: str | None = None,
) -> dict[str, Any]:
    """Read the in-image tool-call trace ring and aggregate counts."""
    params: dict[str, Any] = {"limit": max(1, min(int(limit), 500))}
    if since_sequence is not None:
        params["since_sequence"] = int(since_sequence)
    if tool:
        params["tool"] = tool
    if client_id:
        params["client_id"] = client_id
    return get_json("/png/trace", params)


# --- CircuitTikZ catalog ------------------------------------------------


def ctikz_list_snippets(
    q: str | None = None,
    tag: str | None = None,
    component: str | None = None,
    kind: str | None = None,
) -> dict[str, Any]:
    """List or search the CircuitTikZ snippet catalog."""
    params: dict[str, Any] = {}
    if q:
        params["q"] = q
    if tag:
        params["tag"] = tag
    if component:
        params["component"] = component
    if kind:
        params["kind"] = kind
    return get_json("/ctikz/snippets", params)


def ctikz_get_snippet(snippet_id: str) -> dict[str, Any]:
    """Get one catalog snippet by id, including schema, presets, and checksum."""
    return get_json(snippet_path(snippet_id))


def ctikz_render_snippet(snippet_id: str, parameters: dict[str, Any] | None = None) -> dict[str, Any]:
    """Render one snippet with caller parameters merged over schema defaults and presets."""
    return post_json(
        "/ctikz/render_snippet",
        {"snippet_id": snippet_id, "parameters": parameters or {}},
    )


def ctikz_lookup_component(component: str) -> dict[str, Any]:
    """Look up a CircuitTikZ component key and return its semantic description and snippets."""
    return post_json("/ctikz/components", {"component": component})


# --- CircuitTikZ lint ---------------------------------------------------


def ctikz_lint_source(
    path: str | None = None,
    source_text: str | None = None,
    required_labels: list[str] | None = None,
    forbid_patterns: list[str] | None = None,
    strict: bool = False,
) -> dict[str, Any]:
    """Lint CircuitTikZ source by repository path or exact text."""
    if path is None and source_text is None:
        path = "current/reconstruction.tex"
    payload: dict[str, Any] = {"strict": bool(strict)}
    if path is not None:
        payload["path"] = path
    if source_text is not None:
        payload["source_text"] = source_text
    if required_labels is not None:
        payload["required_labels"] = required_labels
    if forbid_patterns is not None:
        payload["forbid_patterns"] = forbid_patterns
    return post_json("/ctikz/lint", payload)


# --- Common health and trace -------------------------------------------


def dskt_health() -> dict[str, Any]:
    """Report common health and the services map for every registered domain."""
    return get_json("/health")


def dskt_trace(
    limit: int = 50,
    since_sequence: int | None = None,
    tool: str | None = None,
    client_id: str | None = None,
) -> dict[str, Any]:
    """Read the shared trace ring and aggregate counts."""
    params: dict[str, Any] = {"limit": max(1, min(int(limit), 500))}
    if since_sequence is not None:
        params["since_sequence"] = int(since_sequence)
    if tool:
        params["tool"] = tool
    if client_id:
        params["client_id"] = client_id
    return get_json("/trace", params)


TOOLS = [
    ("png", "png_inspect_image", png_inspect_image, READONLY),
    ("png", "png_make_ink_mask", png_make_ink_mask, WRITE),
    ("png", "png_measure_bounds", png_measure_bounds, READONLY),
    ("png", "png_measure_regions", png_measure_regions, READONLY),
    ("png", "png_normalize_geometry", png_normalize_geometry, READONLY),
    ("png", "png_health", png_health, READONLY),
    ("png", "png_trace", png_trace, READONLY),
    ("ctikz_catalog", "ctikz_list_snippets", ctikz_list_snippets, READONLY),
    ("ctikz_catalog", "ctikz_get_snippet", ctikz_get_snippet, READONLY),
    ("ctikz_catalog", "ctikz_render_snippet", ctikz_render_snippet, READONLY),
    ("ctikz_catalog", "ctikz_lookup_component", ctikz_lookup_component, READONLY),
    ("ctikz_lint", "ctikz_lint_source", ctikz_lint_source, READONLY),
    ("dskt", "dskt_health", dskt_health, READONLY),
    ("dskt", "dskt_trace", dskt_trace, READONLY),
]


def _selected_modules() -> set[str]:
    return {item.strip() for item in os.environ.get("DSKT_MODULES", "").split(",") if item.strip()}


def _selected_tools() -> set[str]:
    return {item.strip() for item in os.environ.get("DSKT_TOOLS", "").split(",") if item.strip()}


def _allowed(module: str, name: str, modules: set[str], tools: set[str]) -> bool:
    if tools:
        return name in tools
    if modules:
        return module in modules
    return True


def register_tools() -> None:
    modules = _selected_modules()
    tools = _selected_tools()
    for module, name, function, annotations in TOOLS:
        if _allowed(module, name, modules, tools):
            mcp.tool(function, name=name, annotations=annotations)


def main() -> None:
    register_tools()
    mcp.run()


if __name__ == "__main__":
    main()
