# Objective

Re-create the control block diagram in `reference/control_diagram.png` as an
editable LaTeX document in `current-control/reconstruction.tex`.

`schemabloc` must be the primary diagram implementation mechanism. Ordinary TikZ
may be used only for annotations and connections that schemabloc does not
reasonably express.

The completed source must compile successfully and approximate the target's:

- blocks and their transfer functions;
- comparator and summing junctions, including signs;
- forward, feedforward, and feedback paths;
- signal labels and branch points;
- block order, relative spacing, and alignment;
- overall horizontal composition.

The target image must not be embedded, traced, or used as a raster substitute.