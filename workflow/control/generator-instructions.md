# Control generator instructions

## Required approach

- Use a `tikzpicture` with `schemabloc` as the main drawing mechanism.
- Prefer semantic `sb*` block, comparator, entry, exit, and link macros over
  manually drawn rectangles and lines.
- Preserve node names and signal labels.
- Use ordinary TikZ only for annotations, branch points, and connections that
  schemabloc cannot express cleanly.
- Keep the source compilable and editable across iterations.

## Iteration priorities

Address issues in this order:

1. compilation and invalid LaTeX;
2. missing or wrong blocks/comparators;
3. incorrect signal topology, feedback, or feedforward paths;
4. comparator signs and signal direction;
5. labels and transfer-function text;
6. relative placement, alignment, and spacing;
7. fine visual styling.

## Measurement

Use `png_inspect_image`, `png_measure_bounds`, `png_measure_regions`, and
`png_normalize_geometry` on both `reference/control_diagram.png` and
`current-control/reconstruction.png` before geometry claims. Cite the tool,
raw box or point, basis, mask threshold and background, and warnings.

## Prohibited shortcuts

- Do not embed or trace the target image.
- Do not replace semantic blocks with bare `\draw ... rectangle` stand-ins.
- Do not hide missing elements behind overlays.
- Do not modify the target image.
- Do not edit iteration archives.