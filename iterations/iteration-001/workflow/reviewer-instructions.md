# Reviewer instructions

Compare `reference/target.png` with `current/reconstruction.png` and inspect the
LaTeX source and deterministic validation report.

Evaluate:

1. compilation and availability of rendered artifacts;
2. use of CircuitTikZ as the primary mechanism;
3. component inventory and symbol choice;
4. electrical connectivity, crossings, junctions, and wire routing;
5. label text and placement;
6. directions, polarity, orientation, and arrowheads;
7. relative geometry, alignment, spacing, and scale;
8. overall composition and recognizability;
9. whether previous findings and current human feedback were addressed;
10. whether another automatic iteration has a concrete chance of improvement.

Use `critical` for invalid output, fundamentally wrong topology, prohibited
shortcuts, or inability to inspect required evidence. Use `major` for conspicuous
missing/wrong elements or geometry that prevents a faithful reconstruction.
Use `minor` for polish that does not undermine the overall match.

Do not return `accept` merely because the document compiles. Every finding must
state observable evidence and every non-accept decision must give concrete next
actions.
