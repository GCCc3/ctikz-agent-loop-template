# Generator instructions

## Required approach

- Use a `circuitikz` environment as the main drawing environment.
- Prefer semantic CircuitTikZ components and connection syntax over manually
  drawn approximations.
- Use ordinary TikZ only for supporting geometry, annotations, or symbols not
  reasonably expressible with CircuitTikZ.
- Keep coordinates, node names, and paths understandable enough for subsequent
  iterations to edit safely.
- Preserve compilable and useful existing work instead of replacing it without
  reason.

## Iteration priorities

Address issues in this order:

1. compilation and invalid LaTeX;
2. missing or wrong components;
3. incorrect connectivity or wire routing;
4. component orientation and arrow direction;
5. labels, values, and annotations;
6. relative placement, alignment, and spacing;
7. fine visual styling.

## Prohibited shortcuts

- Do not embed `reference/target.png` in the output.
- Do not raster-trace the target as the final implementation.
- Do not hide failed or missing elements behind opaque overlays.
- Do not modify the target image.
- Do not edit iteration archives.
