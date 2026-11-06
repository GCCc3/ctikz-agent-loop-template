# CircuitTikZ domain rules

1. CircuitTikZ must be the primary diagram implementation mechanism.
2. Prefer semantic electrical components over manually drawn visual stand-ins.
3. Ordinary TikZ may support annotations and constructs not reasonably
   expressible with CircuitTikZ.
4. Preserve visible text, symbols, polarity, directions, and connectivity.
5. Keep the source editable, explicit, and understandable.
6. Use project-relative paths for local resources.
7. The reference image must not appear in the generated output.
8. Raster tracing is not an acceptable final implementation.
9. Avoid premature macros and abstractions unless repetition clearly warrants
   them.
10. A visual resemblance cannot compensate for electrically wrong topology.
