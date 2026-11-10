---
name: png-diagram-measure
description: Measure PNG diagram geometry with the PDM MCP tools and cite raw boxes, threshold, background, and basis.
---

# PNG diagram measurement

Use these tools before making any geometry, crop, margin, aspect-ratio, or
physical-size claim about a PNG diagram. The tools are read-only unless a tool
explicitly writes under `tmp/png-measure/`.

## Workflow

1. Call `png_inspect_image` once per image. Refuse to measure an unsupported PNG.
2. Call `png_measure_bounds` before any crop, margin, aspect-ratio, or
   physical-size claim.
3. Call `png_measure_regions` for named windows. Prefer `normalized_ink`.
   Enlarge a window when the result warns `region_ink_extends_beyond_window`.
4. Call `png_normalize_geometry` to convert explicit TeX coordinates into the
   same basis as the measurement.
5. Call `png_create_baseline` once for `reference/target.png`. Without
   `output_path` it returns the document and writes nothing. The coordinator
   promotes the result into `reference/`.
6. Cite the raw box, threshold, background, and basis with every number. Never
   describe a measurement as a semantic identification.
7. Use `png_trace` only to audit tool usage or answer a human question. It is
   diagnostic, not measurement evidence, and is never part of the measurement
   loop.

## Citation rule

For each geometry claim include:

- tool name;
- raw pixel box or normalized coordinates;
- mask `threshold` and `background`;
- basis (`image_pixels`, `normalized_image`, `ink_pixels`, `normalized_ink`, or
  `centimetres`);
- warning codes that apply.

Do not cite an absolute image path. Use the repo-relative path.
