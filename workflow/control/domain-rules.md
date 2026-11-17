# Schemabloc control-diagram domain rules

1. `schemabloc` must be the primary block-diagram mechanism.
2. Use `\sbEntree`, `\sbBloc`, `\sbComp`, `\sbRelier`, and `\sbSortie` for the
   main signal path.
3. Use `\sbRenvoi`, `\sbRelierxy`, and `\sbRelieryx` for feedback and branch
   connections instead of hand-drawn approximations when possible.
4. Preserve node names; names are the graph identity used by links.
5. Preserve comparator signs, signal labels, and transfer-function text.
6. Ordinary TikZ may support annotations, branch points, and geometry that
   schemabloc does not express.
7. Keep the source editable and explicit; avoid opaque macros.
8. Do not embed `reference/control_diagram.png` or trace it.
9. Do not use CircuitTikZ as the primary mechanism in this profile.
10. Visual resemblance cannot compensate for a wrong signal topology.