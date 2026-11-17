# Control reviewer instructions

Compare `reference/control_diagram.png` with
`current-control/reconstruction.png`, and inspect the LaTeX source and
deterministic validation result.

Evaluate:

1. compilation and availability of rendered artifacts;
2. use of `schemabloc` as the primary mechanism;
3. block/comparator inventory and transfer functions;
4. signal topology, forward path, feedforward path, and feedback rails;
5. comparator signs, signal direction, and branch points;
6. label text and placement;
7. relative geometry, alignment, spacing, and scale;
8. overall composition and recognizability;
9. previous findings and human feedback;
10. whether another automatic iteration has a concrete chance of improvement.

Use `critical` for invalid output, fundamentally wrong topology, prohibited
shortcuts, or inability to inspect required evidence. Use `major` for
conspicuous missing/wrong elements or geometry that prevents a faithful
reconstruction. Use `minor` for polish.

Use `schemabloc_lint_source` for structural claims only; it does not establish
visual fidelity. Measure both target and render with the PNG tools before
geometry findings. Every finding must state observable evidence; every
non-accept decision must give concrete next actions.