---
title: How the proposed measure_diagram_geometry MCP tool would work
date: 2026-11-05
status: proposal (not implemented)
source: analysis/efficiency-through-003.md (tool proposal 1, confidence high)
patternsAddressed: [P1, P2, P5, P6, P9]
note: >-
  Stage-by-stage design of the first proposed tool, grounded in the measured
  artifacts of this repository: reference/target.png (696x252 px),
  current/reconstruction.tex and current/reconstruction.png (889x333 px at
  180 dpi), plus the archived iteration-1 render (1530x1980 px).
---

Grounding the six stages in the actual artifacts: `reference/target.png` (696×252 px), `current/reconstruction.tex` (iteration 3), `current/reconstruction.png` (889×333 px at 180 dpi), and the archived renders (iteration 1: 1530×1980 px).

## 1. Decode and threshold

**Mechanism.** Format dispatch on magic bytes. PNG: inflate the IDAT stream, undo the five per-scanline filters (None/Sub/Up/Average/Paeth), then reduce channels to luminance — gray, RGB, or RGBA with alpha below a cutoff folded into the background. PDF: read the page box with `pdfinfo`, rasterize with `pdftoppm -r dpi` (what `render.sh` already does at 180). Binarize at one declared threshold and echo it. No model, no network.

**Case.** The target is RGBA; the render from `pdftoppm` is RGB — the decoder has to handle both, which is why the iteration-2b agent's hand-rolled `zlib`+`struct` decoder (five bash calls, ~200 lines) was a real, repeated cost. Iteration 1's reviewer never decoded at all and wrote `reference/target.png is ~770x285 px (aspect ~2.7)`; the file is 696×252 (aspect 2.762). My own probes used `<128` and `<160` and moved boxes by at most one pixel — harmless, but only because it was stated. The tool pins the threshold so two passes cannot silently use different ones.

**Prevents.** P1's fabricated dimensions and P6's throwaway decoders. Any claim about pixel counts comes from one implementation.

## 2. Establish the drawing frame

**Mechanism.** Compute the ink bounding box over the whole image, derive per-side margins and the page aspect, and set `tight_crop` by comparing ink box to page box within a tolerance (a couple of pixels, plus the declared `border`). `drawing_bbox` overrides it when page furniture would contaminate the frame. All later fractions divide by this frame, and the frame is printed.

**Case.**

| artifact | page px | ink bbox | margins (L/R/T/B) | page aspect | ink aspect | tight_crop |
|---|---|---|---|---|---|---|
| `reference/target.png` | 696×252 | x 16–683, y 13–240 → 667×227 | 16/12/13/11 | 2.762 | 2.938 | true |
| iteration‑1 render | 1530×1980 | letter page, drawing confined to top band | hundreds | 0.773 | ~2.7 | **false** |
| iteration‑3 render | 889×333 | x 15–872, y 15–316 → 858×302 | ~15–16 each | 2.670 | 2.847 | true |

The 15 px margin is exactly `border=6pt` at 180 dpi (6/72 × 180), which is how the tool distinguishes "cropped to the declared border" from "cropped by accident".

**Prevents.** P5 entirely: iteration 1 spent about ten calls (`render.sh`, render log, `standalone.cls`, `preview.sty`, `.fls`, two LaTeX probes) concluding what one boolean and one margin column state. It also exposes something no pass noticed: the target's ink aspect (2.938) and the render's (2.847) differ by ~3%, because the target's vertical margins are proportionally smaller — a real composition delta that eyeballing missed.

## 3. Measure regions

**Mechanism.** The caller supplies named pixel windows; the tool tightens each to the ink inside, and reports bbox, centre, width/height in px (and cm when DPI is known), plus four fractions. Names are never invented — a caller who wants to know "is the label clear of the divider" asks for `z_g_label` and `divider` separately. Without `regions`, connected components are returned as unlabeled candidates.

**Case.** Windows over the target:

| name | window | tightened ink | result |
|---|---|---|---|
| `converter_block` | 30,50–200,215 | 40–184 × 61–205 | 144×144 px, square, top edge 12 px above the wire |
| `z_g_body` | 500,50–600,95 | 527–589 × 55–90 | 62×35 px, frac 0.766–0.859 |
| `z_g_label` | 535,20–580,55 | 543–569 | centre 556 vs body centre 558 |
| `divider` | 455,20–505,235 | 468–493 | both dashed columns, frac 0.678–0.715 |

The failure mode this replaces is visible in the transcripts: iteration 1 reported `Z_g 0.67-0.75 target` — a window that caught the divider column and the left part of the body as one blob. The tool does not silently return that: two disconnected components inside one window produce a `multiple_components` warning with both boxes, so the reviewer sees "I measured two things" instead of a single confident wrong number.

**Prevents.** P1's eyeballed boxes and P9's seed error. When iteration 2 drew `Z_g` at 8.05–9.00 with the divider at 8.35–8.45, the region genuinely contained one merged component; the tool would have said so at generation time, not at review time.

## 4. Measure the source

**Mechanism.** A token scan over explicit constructs: `\coordinate (n) at (x,y)`, `\draw … rectangle (x0,y0) … (x1,y1)`, `node at (x,y)`, and path endpoints. Compute the source's own bbox, then emit the same cm and fraction fields, declaring the y orientation (image coordinates run top-down, TeX bottom-up) so a fraction taken from source is comparable to one taken from pixels. Forms it cannot evaluate (`++`, `calc`, `\foreach`, macros) are skipped and listed.

**Case.** Parsing iteration 3's source yields bbox 0–12.1 × −0.95–3.3 (12.1×4.25 cm), and:

| element | source value | cm | fraction |
|---|---|---|---|
| `z1`, `z2` | (9.3,2.2), (10.35,2.2) | 9.3–10.35 | 0.7686–0.8554 |
| divider boxes | 8.35 / 8.45 | — | 0.6901 / 0.6983 |
| block | rect (0.5,0)–(3.0,2.5) | 2.5×2.5 | 0.0413–0.2479 |
| labels | 4.55 / 6.125 / 9.825 | — | 0.376 / 0.506 / 0.812 |
| AC label | block-relative (2.35,0.35) | — | 74% across, 86% down |

Those reproduce the generator's hand arithmetic (`GenIteration3` wrote "0.769-0.855 of the 12.1 cm width"), and expose the slips that hand arithmetic admits: `GenIteration2Gen` claimed AC at "74% across / 87% down" when (2.5−0.35)/2.5 = 86%.

What it deliberately cannot supply: symbol geometry from `to[L]`, `to[R]`, `to[generic]`, `to[sV]`. The path span is known (9.3–10.35), the rectangle's 20 px height and the coil's 0.21-scale bumps are CircuitTikZ's business — the tool marks those elements `kind: path` and points at `lookup_circuitikz_component` and the render measurement.

**Prevents.** P2: six occurrences of the same `(x − x0)/width` arithmetic on three different drawing widths (13.9 cm in iteration 1, 12.0 in iteration 2, 12.1 in iteration 3).

## 5. Compare and diff

**Mechanism.** The same regions run against `compare_image` and/or a cached `baseline_json`; deltas are per element and in both fraction and px (1 px = 0.00117 of an 858 px frame, so a 0.004 delta is 3.4 px — the unit matters to severity). Baselines are keyed by a hash of image bytes plus parameters, so a stale baseline is detectable rather than silently authoritative. Cross-iteration comparison uses an earlier report as baseline.

**Case, target vs iteration‑3 render:**

| element | target frac | render frac | delta |
|---|---|---|---|
| `z_g_body` | 0.7661–0.8591 | 0.7655–0.8590 | ≈0.001 (sub-pixel) |
| `divider` | 0.6777–0.7151 (width 0.037) | 0.6908–0.6989 (width 0.008) | width differs by 0.029 — the divider gap |
| `converter_block` right | 0.252 | 0.249 | 0.003 |
| `GFM converter` caption centre | 0.436 | 0.413 | 0.023 (~20 px) |
| `v_g` source centre | 0.929 | 0.921 | 0.008 |

Two things follow. First, the `Z_g` question is settled as a ~0.001 delta, not as prose. Second, the divider-gap delta (target 22 px of white between the dashed boxes; render 0.1 cm ≈ 7 px) is a genuine, unflagged difference that only appears when both frames are measured the same way — iteration 3's reviewer did not report it.

**Prevents.** P9's reversal loop: iteration 1 claimed the target's `Z_g` was at 0.67–0.75, iteration 2 claimed 0.77–0.86, iteration 3 settled at 0.769–0.855. The tool's answer is 0.766–0.859 with the raw box attached, so the next pass recomputes instead of re-litigating.

## 6. Output and warnings

**Mechanism.** One JSON object, sorted keys, integer pixels, no timestamps — byte-identical for identical inputs, which is what makes baseline hashing and "re-run the same claim" meaningful. Raw boxes are always retained so any derived fraction can be audited. `warnings` is where every ambiguity that would otherwise become a confident wrong statement lands: merged components, ink clipped by a window edge, boxes moving ≥1 px across thresholds, unknown DPI (cm reported as null, not guessed), unsupported TeX constructs, symbol extent unavailable, and frames measured against different denominators.

**Case, one element in the response:**

```json
"elements": [
  {"name": "z_g_body", "kind": "ink",
   "x0": 527, "y0": 55, "x1": 589, "y1": 90,
   "cx": 558, "cy": 72, "width_px": 62, "height_px": 35,
   "width_cm": null, "height_cm": null,
   "frac_x0": 0.7661, "frac_x1": 0.8591,
   "frac_y0": 0.1850, "frac_y1": 0.3392}
],
"compare": {"path": "current/reconstruction.png", "width_px": 889, "height_px": 333,
            "dpi": 180, "tight_crop": true, "ink_bbox_px": [15,15,872,316]},
"deltas": [{"name": "z_g_body", "dx_frac": -0.0006, "dw_frac": -0.0005}],
"warnings": ["compare frame: fractions normalized per image (target 667 px, render 858 px)",
             "primary dpi unknown: width_cm/height_cm omitted"]
```

`width_cm: null` on the target is the honest part: iteration 2's reviewer asserted "≈66.6 px/cm" for the target by fitting a 12.1 cm drawing onto a guessed 806 px width — an assumption with nothing behind it. The tool refuses that and forces comparisons onto fractions.

**Prevents.** The failure class where a number measured loosely becomes a nextAction: iteration 1's `Z_g 0.67-0.75` and `~770x285 px` were both about 5–10% off, were never recomputed, and cost one generation pass. Everything the tool emits is recomputable from the quoted bytes and parameters; everything it emits is a fact about ink, never a verdict about whether the diagram is good enough.
