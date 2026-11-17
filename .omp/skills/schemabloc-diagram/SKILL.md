---
name: schemabloc-diagram
description: Build and lint schemabloc control block diagrams with the schemabloc MCP tools.
---

# Schemabloc control diagrams

Use `schemabloc` macros in a single `tikzpicture`. Prefer semantic block and
link macros over manual rectangles and lines.

## Workflow

1. Call `schemabloc_list_snippets` to find the macro for the construct.
2. Call `schemabloc_get_snippet` to inspect required parameters.
3. Render leaf constructs with `schemabloc_render_snippet`.
4. Use `schemabloc_lookup_component` for macro semantics.
5. Measure `reference/control_diagram.png` and `current-control/reconstruction.png`
   with `png_inspect_image`, `png_measure_bounds`, `png_measure_regions`, and
   `png_normalize_geometry` before geometry claims.
6. Before writing the candidate, run `schemabloc_lint_source` and resolve failed
   checks. Warnings require judgement.
7. Cite tool, raw box or point, basis, mask threshold/background, and warning
   codes for every measurement.

## Rules

- Use `\sbEntree`, `\sbBloc`, `\sbComp`, `\sbRelier`, and `\sbSortie` for the
  main path.
- Use `\sbRenvoi`, `\sbRelierxy`, and `\sbRelieryx` for feedback and branch
  links.
- Preserve node names; they are the graph identity.
- Preserve comparator signs, signal labels, and transfer functions.
- Ordinary TikZ is only for annotations and constructs schemabloc cannot
  express.
- Do not embed or trace `reference/control_diagram.png`.
- Do not use CircuitTikZ as the primary mechanism.
- Do not use `png_create_baseline`; the baseline feature was removed.
