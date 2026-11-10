"""FastMCP tools for the PNG diagram measurement service."""

from __future__ import annotations

import uuid
from typing import Annotated, Any

from fastmcp import FastMCP
from pydantic import Field

from .core import (
    ShimError,
    _trace_line,
    envelope_error,
    get_path,
    operation_payload,
    output_root,
    post_operation,
)

mcp = FastMCP(
    "png-diagram-measure",
    instructions=(
        "Measure PNG diagram geometry through a Pharo service. "
        "Inspect an image before measuring, cite raw boxes and the mask basis, "
        "and use png_trace only for usage audits."
    ),
)


def _reject(tool: str, image_path: str | None, error: ShimError) -> dict[str, Any]:
    _trace_line(
        request_id=str(uuid.uuid4()),
        tool=tool,
        outcome="rejected",
        error_code=error.code,
        image_path=image_path,
    )
    return envelope_error(error)


def _operate(
    tool: str,
    image_path: str,
    *,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    try:
        payload = operation_payload(image_path, mask=mask, dpi_override=dpi_override)
        if extra:
            payload.update(extra)
        return post_operation(tool, payload)
    except ShimError as error:
        return _reject(f"png_{tool}", image_path, error)
    except Exception as error:  # pragma: no cover - defensive transport boundary
        return envelope_error(error)


@mcp.tool(annotations={"readOnlyHint": True})
def png_inspect_image(
    image_path: str,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Inspect a PNG and report dimensions, colour type, alpha, and resolution."""
    return _operate("inspect_image", image_path, mask=mask, dpi_override=dpi_override)


@mcp.tool(annotations={"readOnlyHint": False, "destructiveHint": False, "idempotentHint": True, "openWorldHint": False})
def png_make_ink_mask(
    image_path: str,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Create a deterministic binary ink-mask PNG under the configured output root."""
    return _operate("make_ink_mask", image_path, mask=mask, dpi_override=dpi_override)


@mcp.tool(annotations={"readOnlyHint": True})
def png_measure_bounds(
    image_path: str,
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Measure the canvas, ink bounds, margins, aspect ratios, and tight-crop status."""
    return _operate("measure_bounds", image_path, mask=mask, dpi_override=dpi_override)


@mcp.tool(annotations={"readOnlyHint": True})
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
        return _reject(
            "png_measure_regions",
            image_path,
            ShimError("invalid_request", "regions must be a non-empty object"),
        )
    if region_units not in {"normalized_ink", "normalized_image", "image_pixels"}:
        return _reject(
            "png_measure_regions",
            image_path,
            ShimError("unknown_basis", f"Unsupported region_units: {region_units}"),
        )
    extra: dict[str, Any] = {"regions": regions, "region_units": region_units}
    if image_sha256 is not None:
        extra["image_sha256"] = image_sha256
    return _operate("measure_regions", image_path, mask=mask, dpi_override=dpi_override, extra=extra)


@mcp.tool(annotations={"readOnlyHint": True})
def png_normalize_geometry(
    image_path: str,
    geometry: dict[str, Any],
    from_basis: Annotated[str, Field(alias="from")],
    to_basis: Annotated[str, Field(alias="to")],
    mask: dict[str, Any] | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Convert a point or box between image, ink, normalized, and centimetre bases."""
    extra = {"geometry": geometry, "from": from_basis, "to": to_basis}
    return _operate("normalize_geometry", image_path, mask=mask, dpi_override=dpi_override, extra=extra)


@mcp.tool(annotations={"readOnlyHint": False, "destructiveHint": False, "idempotentHint": True, "openWorldHint": False})
def png_create_baseline(
    image_path: str,
    regions: dict[str, list[float]] | None = None,
    region_units: str = "normalized_ink",
    mask: dict[str, Any] | None = None,
    output_path: str | None = None,
    dpi_override: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Build a deterministic baseline document, optionally writing it under the output root."""
    extra: dict[str, Any] = {"region_units": region_units}
    if regions is not None:
        extra["regions"] = regions
    if output_path is not None:
        target = (output_root() / output_path).resolve()
        try:
            target.relative_to(output_root())
        except ValueError:
            return _reject(
                "png_create_baseline",
                image_path,
                ShimError("output_path_rejected", "output_path escapes the output root"),
            )
        extra["output_path"] = output_path
    return _operate("create_baseline", image_path, mask=mask, dpi_override=dpi_override, extra=extra)


@mcp.tool(annotations={"readOnlyHint": True})
def png_health() -> dict[str, Any]:
    """Report service health, version, port, output root, cache, and trace status."""
    return get_path("/png/health")


@mcp.tool(annotations={"readOnlyHint": True})
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
    return get_path("/png/trace", params)


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
