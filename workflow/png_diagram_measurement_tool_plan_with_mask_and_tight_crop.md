# PNG Diagram Measurement Tool Plan

## 1. Scope

This plan defines a compact tool for measuring diagrams supplied as conventional PNG screenshots. The tool is intended to support an agent that reconstructs a diagram in LaTeX and needs deterministic geometric measurements from the reference image.

The supported public operations are:

1. `inspect_image`
2. `make_ink_mask`
3. `measure_bounds`
4. `measure_regions`
5. `normalize_geometry`
6. `create_baseline`

These operations may be exposed through one MCP entry point, such as `analyze_png_diagram`, with an `action` field selecting the requested operation.

---

## 2. Common conventions

### 2.1 Conventional screenshot assumption

The first implementation assumes conventional screenshots with these properties:

- PNG format;
- 8-bit colour channels;
- non-interlaced encoding;
- grayscale, RGB, indexed colour, grayscale-alpha, or RGBA colour type;
- a white or near-white page background;
- no requirement to support 16-bit samples or Adam7 interlacing;
- diagrams dominated by dark lines and text on a light background.

If an input falls outside these assumptions, `inspect_image` must return an explicit unsupported-format error rather than silently interpreting it incorrectly.

### 2.2 Pixel coordinates

Raster coordinates use:

- origin at the top-left corner;
- positive `x` to the right;
- positive `y` downward;
- bounding boxes represented as `[x0, y0, x1, y1]`;
- exclusive `x1` and `y1`, so width and height are:

\[
W=x_1-x_0
\]

\[
H=y_1-y_0
\]

The complete image box for an image of width `W` and height `H` is therefore:

```json
[0, 0, W, H]
```

### 2.3 Normalized coordinates

Normalized coordinates range from 0 to 1 relative to an explicitly named basis, for example:

- `image`;
- `ink_bbox`;
- `drawing_bbox`.

A normalized value is invalid unless its basis is stated. For example, `x = 0.5` may mean the centre of the full image or the centre of the detected ink area, which are not necessarily the same point.

### 2.4 Physical dimensions

Physical dimensions may be returned only when the PNG contains valid physical-resolution metadata or the caller supplies a trusted DPI override.

For known DPI:

\[
\text{cm}=\text{px}\times\frac{2.54}{\text{DPI}}
\]

If DPI is unknown, centimetre values must be `null` and accompanied by a warning. The tool must not silently assume a pixel-per-centimetre conversion.

### 2.5 Deterministic output

For identical image bytes and parameters, the tool should return byte-identical JSON by using:

- sorted keys;
- repository-relative paths;
- an explicit schema version;
- no timestamps in deterministic output;
- the image SHA-256;
- all thresholds and coordinate bases used.

---

# 3. Operations

## Operation 1: `inspect_image`

### Purpose

Validate and decode a conventional PNG screenshot, then report the metadata needed by subsequent operations.

### Input

```json
{
  "action": "inspect_image",
  "image_path": "reference/target.png"
}
```

No advanced PNG options are exposed in the first implementation.

### Processing

The operation must:

1. validate the PNG signature;
2. read `IHDR` for width, height, bit depth, colour type, and interlace method;
3. read `pHYs` when present to determine physical resolution;
4. read `PLTE` and `tRNS` when required by indexed or transparent images;
5. concatenate and inflate `IDAT` data with `zlib`;
6. reverse the five PNG scanline filters;
7. decode the pixels into one internal 8-bit RGBA representation;
8. calculate the SHA-256 of the input file.

### Supported input

The initial implementation supports:

- bit depth 8;
- non-interlaced PNGs;
- grayscale;
- RGB;
- indexed colour;
- grayscale with alpha;
- RGBA.

It rejects unsupported bit depths or interlacing with a clear diagnostic.

### Output

```json
{
  "schema_version": 1,
  "image": {
    "path": "reference/target.png",
    "sha256": "...",
    "width_px": 696,
    "height_px": 252,
    "bit_depth": 8,
    "colour_type": "rgba",
    "has_alpha": true,
    "interlaced": false
  },
  "resolution": {
    "dpi_x": 120.0,
    "dpi_y": 120.0,
    "source": "metadata"
  },
  "warnings": []
}
```

If physical resolution is unavailable:

```json
{
  "resolution": {
    "dpi_x": null,
    "dpi_y": null,
    "source": "unknown"
  },
  "warnings": [
    "The PNG does not provide physical resolution metadata"
  ]
}
```

### Failure conditions

The operation must fail explicitly when:

- the file is not a valid PNG;
- the PNG is truncated or has invalid chunk data;
- decompression fails;
- the bit depth is not 8;
- Adam7 interlacing is used;
- the colour type is unsupported.

---

## Operation 2: `make_ink_mask`

### Purpose

Classify every visible pixel as diagram ink or background and return the generated binary mask as a PNG image for inspection and reuse by subsequent operations.

### Input

```json
{
  "action": "make_ink_mask",
  "image_path": "reference/target.png",
  "background": "#ffffff",
  "method": "luminance",
  "threshold": 0.5,
  "sensitivity_thresholds": [0.25, 0.5, 0.75]
}
```

### Processing

#### 1. Composite transparency over the background

For each normalized colour channel:

\[
C_{visible}=\alpha C_{foreground}+(1-\alpha)C_{background}
\]

This ensures that a fully transparent black pixel is interpreted as the background rather than as black ink.

#### 2. Calculate visible luminance

\[
L=0.2126R+0.7152G+0.0722B
\]

where `R`, `G`, and `B` are normalized to the range 0 to 1.

#### 3. Classify ink

\[
\operatorname{ink}(p)=
\begin{cases}
1 & L(p)<\tau\\
0 & L(p)\geq\tau
\end{cases}
\]

The default threshold is `0.5`.

#### 4. Measure threshold sensitivity

Repeat the bounding-box calculation at the configured sensitivity thresholds. This reveals whether antialiasing or faint pixels materially change the detected diagram boundary.

### Output

The operation returns mask statistics and measurements together with the generated binary mask PNG:

```json
{
  "mask_id": "mask-<image-hash>-lum-0.5",
  "mask_path": "artifacts/target.ink-mask.png",
  "mask_format": "png",
  "mask_encoding": {
    "ink": 0,
    "background": 255
  },
  "method": "luminance",
  "threshold": 0.5,
  "background": "#ffffff",
  "ink_pixel_count": 18462,
  "ink_fraction": 0.1053,
  "ink_bbox_px": [12, 9, 685, 243],
  "bbox_sensitivity": {
    "0.25": [13, 10, 684, 242],
    "0.50": [12, 9, 685, 243],
    "0.75": [11, 8, 686, 244]
  },
  "warnings": []
}
```

### Warnings

The operation should warn when:

- no ink is found;
- nearly the entire image is classified as ink;
- the bounding box changes materially across sensitivity thresholds;
- the background is not predominantly light;
- the selected threshold appears unsuitable for the image.

### Mask artifact requirements

The returned mask must:

- be an 8-bit grayscale PNG;
- have exactly the same pixel dimensions as the source image;
- encode ink as black (`0`) and background as white (`255`);
- contain no antialiased gray levels because it is a binary classification result;
- use a deterministic filename and content for identical source bytes and parameters;
- be suitable as direct input to `measure_bounds` and `measure_regions`.

### Constraints

- The mask is returned as an 8-bit grayscale PNG, with black (`0`) for ink and white (`255`) for background.
- The returned mask must have the same width and height as the source PNG.
- The mask is also referenced by `mask_id` so later operations in the same request can reuse it without regenerating it.
- The mask filename must be deterministic and derived from the source image name, image hash, and mask parameters.
- The first implementation supports luminance thresholding only.
- Colour-distance, adaptive-threshold, and edge-based methods are deferred.

---

## Operation 3: `measure_bounds`

### Purpose

Measure the full image canvas and the visible ink area, and determine whether the screenshot is tightly cropped. This operation deliberately has no optional drawing-box, border, or crop-tolerance arguments; the tight-crop test uses fixed, documented defaults.

### Input

```json
{
  "action": "measure_bounds",
  "image_path": "reference/target.png",
  "mask": {
    "background": "#ffffff",
    "method": "luminance",
    "threshold": 0.5,
    "sensitivity_thresholds": [0.25, 0.5, 0.75]
  }
}
```

### Processing

1. Inspect and decode the PNG.
2. Create or reuse the internal ink mask.
3. Set the image box to the complete raster.
4. Find the smallest exclusive bounding box containing all ink pixels.
5. Calculate the four blank margins.
6. Calculate image and ink aspect ratios.
7. Determine whether the image is tightly cropped using the fixed rule below.
8. Calculate physical dimensions only when reliable DPI is available.

### Tight-crop rule

The image is reported as `tightly_cropped: true` only when all of the following conditions hold at the primary mask threshold:

1. **Every side margin is small.**

   Horizontal margins must each be no greater than:

   \
   T_x=\max(3\ 	ext{px},\ 0.02W)
   \

   Vertical margins must each be no greater than:

   \
   T_y=\max(3\ 	ext{px},\ 0.02H)
   \

   where `W` and `H` are the full image width and height. The 3-pixel floor avoids classifying tiny screenshots as loose because of normal antialiasing, while the 2% limit prevents substantial blank borders from being accepted.

2. **The ink occupies most of the canvas.**

   \
   	ext{ink coverage of canvas}
   =
   rac{W_{ink}H_{ink}}{WH}
   \geq 0.90
   \

   This is bounding-box coverage, not the fraction of black pixels. Sparse line diagrams can contain little actual ink while still fill their intended drawing area.

3. **The result is stable across sensitivity thresholds.**

   For each edge of the ink bounding box, the maximum displacement across the configured sensitivity thresholds must not exceed:

   \
   T_s=\max(2\ 	ext{px},\ 0.005\max(W,H))
   \

   This avoids declaring an image tightly cropped when the apparent border depends strongly on the luminance threshold.

If one or more conditions fail, `tightly_cropped` is `false`, and `tight_crop_reasons` identifies the failed checks. An empty mask can never be tightly cropped.

For a `696 × 252` screenshot, the fixed limits are:

- horizontal side margin: at most `13.92 px`, evaluated as `13.92` before integer comparison;
- vertical side margin: at most `5.04 px`;
- bounding-box coverage: at least `90%`;
- threshold edge movement: at most `3.48 px`.

The vertical limit is intentionally strict. A screenshot with 9-pixel top and bottom margins is therefore not considered tightly cropped, even if those margins look visually modest.

### Output

```json
{
  "image_bbox_px": [0, 0, 696, 252],
  "ink_bbox_px": [12, 9, 685, 243],
  "image_size_px": {
    "width": 696,
    "height": 252
  },
  "ink_size_px": {
    "width": 673,
    "height": 234
  },
  "margins_px": {
    "left": 12,
    "top": 9,
    "right": 11,
    "bottom": 9
  },
  "aspect_ratio": {
    "image": 2.7619,
    "ink": 2.8761
  },
  "tight_crop": {
    "tightly_cropped": false,
    "margin_limit_px": {
      "horizontal": 13.92,
      "vertical": 5.04
    },
    "bbox_coverage": 0.898,
    "minimum_bbox_coverage": 0.90,
    "sensitivity_limit_px": 3.48,
    "maximum_edge_sensitivity_px": 2,
    "tight_crop_reasons": [
      "Top margin exceeds the vertical margin limit",
      "Bottom margin exceeds the vertical margin limit",
      "Ink bounding-box coverage is below 0.90"
    ]
  },
  "physical_size_cm": {
    "image_width": 14.732,
    "image_height": 5.334,
    "ink_width": 14.245,
    "ink_height": 4.953,
    "source": "metadata"
  },
  "basis": {
    "mask_method": "luminance",
    "threshold": 0.5
  },
  "warnings": []
}
```

When DPI is unavailable, the physical-size fields are `null`.

### Constraints

- This operation does not accept a caller-defined drawing box.
- Tight-crop classification uses the fixed rule documented above; callers cannot silently alter its tolerance.
- It does not apply a presumed LaTeX border size.
- It reports both the Boolean result and the measurements and reasons supporting it.

---

## Operation 4: `measure_regions`

### Purpose

Measure visible ink inside caller-named approximate windows. The operation tightens each window to the ink it contains and returns element-level geometry.

The first implementation does **not** perform connected-component analysis and does not return 4-connected or 8-connected components.

### Input

Regions should normally use normalized coordinates relative to the ink bounding box:

```json
{
  "action": "measure_regions",
  "image_path": "reference/target.png",
  "mask": {
    "background": "#ffffff",
    "method": "luminance",
    "threshold": 0.5,
    "sensitivity_thresholds": [0.25, 0.5, 0.75]
  },
  "regions": {
    "left_converter": [0.03, 0.08, 0.29, 0.91],
    "divider": [0.46, 0.05, 0.54, 0.95],
    "right_dashed_box": [0.61, 0.12, 0.94, 0.87]
  },
  "region_units": "normalized_ink"
}
```

Raw pixel regions may be accepted only when they are tied to the current image SHA-256:

```json
{
  "region_units": "image_pixels",
  "image_sha256": "..."
}
```

### Processing

For each named region:

1. validate the requested box;
2. convert it into image-pixel coordinates;
3. clip it to the image bounds if necessary and report the clipping;
4. examine the internal ink mask strictly inside the window;
5. find the smallest bounding box containing the enclosed ink;
6. calculate its centre, width, height, and aspect ratio;
7. express the tightened box in image pixels and normalized ink coordinates;
8. repeat the tight-box measurement at the sensitivity thresholds.

### Output

```json
{
  "regions": {
    "divider": {
      "status": "measured",
      "requested_bbox": [0.46, 0.05, 0.54, 0.95],
      "requested_basis": "normalized_ink",
      "requested_bbox_px": [322, 21, 376, 232],
      "tight_bbox_px": [341, 22, 349, 229],
      "tight_bbox_normalized_ink": [0.489, 0.056, 0.501, 0.940],
      "center_px": [345.0, 125.5],
      "center_normalized_ink": [0.495, 0.498],
      "size_px": {
        "width": 8,
        "height": 207
      },
      "aspect_ratio": 0.0386,
      "bbox_sensitivity": {
        "0.25": [342, 23, 348, 228],
        "0.50": [341, 22, 349, 229],
        "0.75": [340, 21, 350, 230]
      },
      "warnings": []
    }
  },
  "warnings": []
}
```

If no ink is found:

```json
{
  "status": "empty",
  "tight_bbox_px": null,
  "center_px": null,
  "size_px": null,
  "warnings": [
    "No ink was found inside the requested region"
  ]
}
```

### Constraints

- The operation measures the aggregate ink inside each requested window.
- It does not split multiple disconnected objects.
- It does not infer semantic elements automatically.
- Caller-defined regions are required for element-level measurements.
- Region names are caller-defined identifiers and carry no built-in meaning.

---

## Operation 5: `normalize_geometry`

### Purpose

Convert points and bounding boxes between the known coordinate systems of one PNG image.

This is a deterministic conversion. It does not estimate alignment and does not use least squares.

### Supported coordinate systems

- `image_pixels`;
- `normalized_image`;
- `ink_pixels`;
- `normalized_ink`;
- `centimetres`, only when DPI is known.

### Input example

```json
{
  "action": "normalize_geometry",
  "image_path": "reference/target.png",
  "mask": {
    "background": "#ffffff",
    "method": "luminance",
    "threshold": 0.5
  },
  "geometry": {
    "type": "point",
    "coordinates": [349, 126]
  },
  "from": "image_pixels",
  "to": "normalized_ink"
}
```

### Conversion example

If the ink bounding box begins at `x = 12` and has width `673`, then:

\[
f_x=\frac{349-12}{673}\approx0.501
\]

For the vertical coordinate, with ink beginning at `y = 9` and height `234`:

\[
f_y=\frac{126-9}{234}=0.5
\]

### Output

```json
{
  "geometry": {
    "type": "point",
    "coordinates": [0.501, 0.500]
  },
  "from": {
    "system": "image_pixels",
    "origin": "top_left",
    "x_direction": "right",
    "y_direction": "down"
  },
  "to": {
    "system": "normalized_ink",
    "origin": "ink_bbox_top_left",
    "x_direction": "right",
    "y_direction": "down"
  },
  "transformation": {
    "ink_bbox_px": [12, 9, 685, 243],
    "mask_threshold": 0.5
  },
  "exact": true,
  "warnings": []
}
```

### Supported geometry types

The first implementation supports:

- point;
- axis-aligned bounding box.

Paths, polygons, rotated boxes, and fitted transformations are deferred.

### Constraints

- Normalized outputs must always state their basis.
- Conversion to centimetres fails gracefully when DPI is unknown.
- Geometry outside the destination basis should be returned with an `outside_basis` warning rather than silently clamped.
- Coordinates generated with one mask threshold must not be presented as though they used another threshold.

---

## Operation 7: `create_baseline`

### Purpose

Create a deterministic JSON record of image metadata and measurements. The baseline supports reproducibility, regression testing, and review of later tool changes. This plan does not include a baseline-comparison operation.

### Input

```json
{
  "action": "create_baseline",
  "image_path": "reference/target.png",
  "mask": {
    "background": "#ffffff",
    "method": "luminance",
    "threshold": 0.5,
    "sensitivity_thresholds": [0.25, 0.5, 0.75]
  },
  "regions": {
    "left_converter": [0.03, 0.08, 0.29, 0.91],
    "divider": [0.46, 0.05, 0.54, 0.95]
  },
  "region_units": "normalized_ink",
  "output_path": "reference/target.measurements.json"
}
```

### Processing

1. Run `inspect_image`.
2. Run `make_ink_mask` internally.
3. Run `measure_bounds`.
4. Run `measure_regions` for the supplied named windows.
5. Store the parameters and all measurements in deterministic JSON.
6. Include the image SHA-256 and schema version.

### Baseline contents

- schema version;
- tool version;
- repository-relative image path;
- image SHA-256;
- image dimensions and PNG metadata;
- DPI and its source;
- background colour;
- mask method and threshold;
- sensitivity thresholds;
- image and ink bounds;
- margins and aspect ratios;
- named-region definitions;
- named-region measurements;
- coordinate bases;
- warnings.

### Output example

```json
{
  "schema_version": 1,
  "tool_version": "0.1.0",
  "image": {
    "path": "reference/target.png",
    "sha256": "...",
    "width_px": 696,
    "height_px": 252
  },
  "parameters": {
    "background": "#ffffff",
    "mask_method": "luminance",
    "threshold": 0.5,
    "sensitivity_thresholds": [0.25, 0.5, 0.75],
    "region_units": "normalized_ink"
  },
  "bounds": {},
  "regions": {},
  "warnings": []
}
```

### Determinism requirements

The baseline must use:

- UTF-8 encoding;
- sorted keys;
- consistent numeric precision;
- no timestamps;
- repository-relative paths;
- no machine-specific temporary paths;
- no generated identifiers that vary between runs.

### Constraints

- This operation creates a baseline only.
- It does not compare the baseline with another image or baseline.
- A future comparison tool must validate image hashes, schema versions, mask parameters, and region bases before calculating deltas.

---

# 4. Recommended MCP interface

Expose one MCP tool:

```text
analyze_png_diagram
```

The `action` field selects one of:

```text
inspect_image
make_ink_mask
measure_bounds
measure_regions
normalize_geometry
create_baseline
```

The server should cache decoded pixels and internal masks during one request, but callers should not depend on cache persistence between calls.

---

# 5. Internal implementation modules

The public operations can be implemented with these internal modules:

```text
png_decoder
alpha_compositor
luminance_mask
bounds_measurement
region_measurement
coordinate_conversion
baseline_serializer
```

Suggested responsibilities:

- `png_decoder`: PNG chunks, decompression, filters, and RGBA output;
- `alpha_compositor`: foreground-over-background colour calculation;
- `luminance_mask`: luminance calculation and threshold classification;
- `bounds_measurement`: image box, ink box, margins, and aspect ratios;
- `region_measurement`: named-window validation and tight ink bounds;
- `coordinate_conversion`: pixel, normalized, and physical coordinates;
- `baseline_serializer`: deterministic JSON output.

---

# 6. Implementation order

## Phase 1: decoding and global bounds

Implement:

1. `inspect_image`;
2. internal RGBA decoding;
3. internal alpha compositing;
4. `make_ink_mask`, including deterministic export of the binary mask PNG;
5. `measure_bounds`.

## Phase 2: named-region measurements

Implement:

1. normalized ink-relative region input;
2. region validation and clipping diagnostics;
3. tight regional bounding boxes;
4. centres, sizes, and aspect ratios;
5. threshold-sensitivity reporting.

## Phase 3: coordinate conversion and baselines

Implement:

1. `normalize_geometry` for points and boxes;
2. optional physical units when DPI is known;
3. deterministic `create_baseline` serialization;
4. schema and tool-version fields.

---

# 7. Acceptance criteria

The first version is complete when it can:

1. decode conventional 8-bit, non-interlaced PNG screenshots;
2. reject unsupported PNG variants explicitly;
3. composite transparency over white correctly;
4. classify visible ink using a declared luminance threshold;
5. report threshold-sensitive bounding-box changes;
6. distinguish the full image box from the visible ink box;
7. report margins, dimensions, and aspect ratios;
8. classify tight cropping using fixed margin, coverage, and threshold-stability criteria and report the reasons;
9. measure tight aggregate ink bounds inside caller-named windows;
10. return empty-region warnings instead of fabricated measurements;
11. convert points and boxes between image and ink-relative coordinates;
12. return physical dimensions only when reliable DPI is available;
13. create byte-stable baseline JSON from identical inputs and parameters;
14. return a deterministic grayscale ink-mask PNG with the same dimensions as the source image;
15. never return component-label analysis;
16. never imply semantic understanding of diagram elements.

The governing design principle is that every measurement must state its image, mask parameters, coordinate basis, and units.
