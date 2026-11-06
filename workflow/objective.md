# Objective

Re-create the electrical diagram in `reference/target.png` as an editable
LaTeX document in `current/reconstruction.tex`.

CircuitTikZ must be the primary implementation mechanism. Supporting TikZ
constructs may be used only where CircuitTikZ does not provide a reasonable
construct.

The completed source must compile successfully and approximate the target's:

- electrical components and symbols;
- connectivity and junctions;
- wire routing and arrow directions;
- visible labels and annotations;
- component orientation;
- relative geometry, spacing, and alignment;
- overall visual composition.

The target image must not be embedded, traced, or used as a raster substitute
for reconstructing the diagram.
