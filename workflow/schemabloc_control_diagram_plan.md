> # Schemabloc control-diagram workflow — implementation plan

Status: proposal (not implemented).

## Feasibility

Yes, the folder can support this, but it needs a **second workflow profile** rather than repurposing the CircuitTikZ profile. The shared `DsktServer`, PNG measurement tools, canonical JSON, trace, iteration schemas, and result-persistence scripts are reusable. The CircuitTikZ agents, catalog, scanner, lint rules, validation checks, and paths are not.

Two immediate facts from the repository/environment:

- `reference/control_diagram.png` and the rough `reference/figure3c-schemabloc.tex` exist.
- `schemabloc` is **not installed**; in fact no TeX toolchain is available in the current environment (`kpsewhich`, `pdflatex`, `latexmk`, `tlmgr` are all absent).

The rough example is not a reliable ground truth: it lacks the target’s `Z_g` block and the `\hat v_g` summing junction, and it approximates the feedback/feedforward topology. It should be corrected before being used as an initial reconstruction.

---

## Phase 0 — TeX toolchain and target analysis

### 0.1 Install and verify the TeX stack

- Install TeX Live with `schemabloc` and its dependencies (`pgf`, `amsmath`, `loops`, `latexmk`, `pdftoppm` or ImageMagick).
- Prefer `tlmgr install schemabloc` if a TeX Live installation exists; otherwise install a TeX Live distribution that contains it.
- Add a workspace check:
  - `kpsewhich schemabloc.sty` must return a path.
  - `kpsewhich pgf.sty`, `latexmk`, and a PDF-to-PNG converter must be available.
- Record the installed `schemabloc` version in the control health response.

### 0.2 Correct the seed reconstruction

Create a corrected semantic seed from the rough example:

- `reference/control_diagram.png` remains the target.
- `reference/figure3c-schemabloc.tex` becomes the starting point, not final evidence.
- Add `input/control-initial.tex` containing the corrected seed.
- Correct at least:
  - add the `Z_g` block after `G_Lf^{-1}`;
  - add the `\hat v_g` summing junction on the right;
  - connect `\hat i` between `G_Lf^{-1}` and `Z_g`;
  - verify the `G_ff` feedforward path and the outer voltage/current feedback rails;
  - keep all block labels and comparator signs.
- Compile the seed with `latexmk` before building any catalog or agent.

### 0.3 Inventory the target

Use the existing PNG measurement tools, not a baseline:

- `png_inspect_image` and `png_measure_bounds` on `reference/control_diagram.png`;
- `png_measure_regions` for each block, comparator, branch point, and summing junction;
- `png_normalize_geometry` to convert pixel positions to normalized coordinates;
- calibrate `schemabloc` offsets (`[distance]` is in `em`) by compiling one block and measuring its rendered width/height at the same DPI.

Record the target inventory:

- blocks: `G_va`, `G_ireg`, `G_del`, `G_Lf^{-1}`, `G_ff`, `Z_g`;
- comparators/summers: `sumv`, `sumi`, `summ`, `v_g` sum;
- inputs/outputs: `\hat v_ref`, `\hat i_ref`, `\hat i`, `\hat v`, `\hat v_g`;
- forward path, feedforward path, and both feedback rails.

---

## Phase 1 — Add a control workflow profile

Do not overwrite the existing circuit workflow. Add a profile layer so both workflows coexist in one folder.

### 1.1 Profile configuration

Add:

```text
workflow/profiles/circuit.env
workflow/profiles/control.env
scripts/lib/profile.sh
```

`control.env` should define:

- `WORKFLOW_PROFILE=control`
- `TARGET_IMAGE=reference/control_diagram.png`
- `CURRENT_DIR=current-control`
- `SOURCE_FILE=current-control/reconstruction.tex`
- `ITERATIONS_DIR=iterations-control`
- `WORKFLOW_DIR=workflow/control`
- `GENERATOR_AGENT=control-generator`
- `REVIEWER_AGENT=control-reviewer`
- `PRIMARY_TEX_PACKAGE=schemabloc`
- `VALIDATION_MODE=schemabloc`

Keep `circuit.env` as the default, preserving current behavior.

### 1.2 Parameterize scripts

Update or wrapper these scripts to source the profile:

- `scripts/run.sh` → `scripts/run.sh --profile control`
- `scripts/init-current.sh`
- `scripts/render.sh`
- `scripts/validate.sh`
- `scripts/archive-iteration.sh`
- `scripts/next-iteration-number.sh`
- `scripts/check-workspace.sh`

Required path changes:

- target: `reference/control_diagram.png`;
- source: `current-control/reconstruction.tex`;
- rendered: `current-control/reconstruction.pdf` and `.png`;
- archives: `iterations-control/iteration-NNN`;
- candidates/transcripts: `tmp/control/...`;
- feedback: `workflow/control/current-human-feedback.md`.

Keep the existing `current/` and `iterations/` untouched for the circuit workflow.

---

## Phase 2 — New Pharo domain: `Schemabloc-Core`

Add a new domain next to `tools/circuitikz-tools`:

```text
tools/schemabloc-tools/pharo/src/
├── BaselineOfSchemabloc/
├── Schemabloc-Core/
│   ├── SchemablocSnippet.class.st
│   ├── SchemablocSnippetParameter.class.st
│   ├── SchemablocSnippetCatalog.class.st
│   ├── SchemablocSnippetRenderer.class.st
│   ├── SchemablocSnippetValidator.class.st
│   ├── SchemablocComponentInfo.class.st
│   ├── SchemablocComponentLookup.class.st
│   ├── SchemablocSourceScanner.class.st
│   ├── SchemablocSourceModel.class.st
│   ├── SchemablocLintCheck.class.st
│   ├── SchemablocLintReport.class.st
│   ├── SchemablocLintRule.class.st
│   ├── SchemablocLintService.class.st
│   ├── SchemablocCatalogService.class.st
│   └── SchemablocRouteProvider.class.st
└── Schemabloc-Tests/
```

Reuse `Dskt-Core`: `DsktServer`, `DsktPathResolver`, `DsktCanonicalJson`, `DsktError`, `DsktToolTrace`, `DsktVersion`.

Avoid coupling to `CtikzSnippet*`: create parallel `SchemablocSnippet*` classes. The schemabloc catalog has different parameters and validation rules. A later refactor can extract a common `Dskt-Snippet` layer if the duplication becomes material.

### 2.1 Catalog snippets

Add snippets for the schemabloc macros used by the target:

| Snippet id | Renders |
|---|---|
| `preamble/schemabloc-standalone` | `\documentclass`, `amsmath`, `schemabloc`, `\usetikzlibrary` |
| `entry` | `\sbEntree{name}` |
| `block` | `\sbBloc[offset]{name}{content}{previous}` |
| `block-linked` | `\sbBlocL[offset]{name}{content}{previous}` |
| `block-right` | `\sbBlocr[offset]{name}{content}{previous}` |
| `block-right-linked` | `\sbBlocrL[offset]{name}{content}{previous}` |
| `block-alone` | `\sbBlocSeul[offset]{input}{content}{output}` |
| `comparator` | `\sbComp[offset]{name}{previous}` |
| `comparator-star` | `\sbComp*[offset]{name}{previous}` |
| `comparator-horizontal` | `\sbComph[offset]{name}{previous}` |
| `sum-b` / `sum-h` | `\sbSumb` / `\sbSumh` variants |
| `combined-sum` | `\sbCompSum[offset]{name}{previous}{a}{b}{c}{d}` |
| `link` | `\sbRelier[label]{from}{to}` |
| `return-link` | `\sbRenvoi[offset]{link}{comparator}{label}` |
| `link-xy` | `\sbRelierxy[label]{block}{comparator}` |
| `link-yx` | `\sbRelieryx{link}{block}` |
| `shift-x` / `shift-y` | `\sbDecaleNoeudx` / `\sbDecaleNoeudy` |
| `name-link` | `\sbNomLien[offset]{link}{label}` |
| `exit` | `\sbSortie[offset]{name}{previous}` |
| `style-block` | `\sbStyleBloc{options}` |
| `style-link` | `\sbStyleLien{options}` |
| `style-sum` | `\sbStyleSum{options}` |
| `annotation` | ordinary TikZ node for a target-specific annotation |

Catalog policy:

- no target-specific labels, coordinates, or block names as defaults;
- `content` and `label` are caller-supplied;
- preserve braces, backslashes, `_`, `^`, and math delimiters exactly;
- reject unresolved Mustache placeholders at render time;
- validate required macro arguments and optional offset syntax.

### 2.2 Component lookup

Add `SchemablocComponentLookup` for macro facts:

- macro name;
- human-readable description;
- argument count/roles;
- optional arguments;
- whether it defines a node;
- whether it consumes a previous node;
- whether it draws a link.

Do not pretend to parse the entire `schemabloc.sty`; use a curated manifest plus an optional style-file check. The lookup is for macro semantics, not target-specific components.

### 2.3 Scanner and source model

Create `SchemablocSourceScanner` that extracts:

- `\usepackage{schemabloc}` and `\usetikzlibrary`;
- `tikzpicture` environment boundaries;
- every `\sb*` macro invocation with its arguments;
- defined nodes from `\sbEntree`, `\sbBloc*`, `\sbComp*`, `\sbSortie`, `\sbDecale*`;
- links from `\sbRelier`, `\sbRenvoi`, `\sbRelierxy`, `\sbRelieryx`;
- labels from `\sbRelier[...]`, `\sbRenvoi{...}{...}{label}`, and ordinary `\node`;
- comments, escaped `%`, braces, environments, and verbatim/`\verb` spans.

Extract shared TeX scanning primitives into `Dskt-Tex` if practical: comment stripping, brace/environment balance, line maps, verbatim masking. Then have both `CtikzSourceScanner` and `SchemablocSourceScanner` use them. This avoids duplicating subtle comment/brace behaviour.

### 2.4 Lint rules

Add `SchemablocLintRule` subclasses:

- `single_tikzpicture` — exactly one `tikzpicture`;
- `schemabloc_package` — `\usepackage{schemabloc}` present;
- `no_circuitikz` — control profile must not load or use CircuitTikZ;
- `no_image_inclusion` — no `\includegraphics`, `control_diagram.png`, or `target.png`;
- `balanced_braces` and `balanced_environments`;
- `defined_nodes` — every link endpoint resolves to a defined `sb*` node;
- `duplicate_nodes` — no repeated node name;
- `defined_links` — `\sbRenvoi`/`\sbRelierxy`/`\sbRelieryx` refer to existing links/nodes;
- `comparator_signs` — comparators have the expected visible plus/minus evidence;
- `required_labels` — caller-supplied list, default empty; no target-specific defaults in the catalog;
- `component_inventory` — counts blocks, comparators, links, entries, exits;
- `manual_block_warning` — warn when a block is drawn as a bare `\draw ... rectangle` instead of an `sb*` block;
- `unknown_sb_macro` — warning for unrecognized `\sb*` commands.

The rough example should pass package/balance checks and fail or warn on the missing `Z_g`/`v_g` topology only if those are represented as required nodes; do not bake target labels into the catalog.

### 2.5 Routes and health

`SchemablocRouteProvider` registers:

- `GET /schemabloc/health`
- `GET /schemabloc/snippets`
- `GET /schemabloc/snippets/<id>`
- `POST /schemabloc/render_snippet`
- `POST /schemabloc/components`
- `POST /schemabloc/lint`

Health reports `catalog_status`, `catalog_version`, `snippet_count`, `lint_rules_version`, and `schemabloc_sty_path` / `schemabloc_version`.

Trace details should follow the Ctikz pattern: `tool_family`, `snippet_id`, `source_path`, `check_counts`, `catalog_version`, `lint_rules_version`.

---

## Phase 3 — MCP tools and schemas

Add to `tools/dskt/mcp`:

- `schemabloc_list_snippets`
- `schemabloc_get_snippet`
- `schemabloc_render_snippet`
- `schemabloc_lookup_component`
- `schemabloc_lint_source`
- `schemabloc_health`

Register them under modules `schemabloc_catalog` and `schemabloc_lint`, so `DSKT_MODULES`/`DSKT_TOOLS` can restrict them.

Add schemas:

- `schemas/schemabloc-snippets.schema.json`
- `schemas/schemabloc-lint.schema.json`

Reuse the existing generation/review/validation/iteration schemas if they are generic enough; otherwise add control-specific variants.

Add the Schemabloc baseline to the shared install path:

- load `BaselineOfSchemabloc` in `scripts/ctikz-tools-install.sh` (or rename it to `scripts/dskt-install.sh`);
- assert the `schemabloc` provider is registered before snapshotting;
- no second image or port.

---

## Phase 4 — Agents and workflow

Add new roles rather than overloading the circuit roles:

```text
.omp/agents/control-generator.md
.omp/agents/control-reviewer.md
```

### Generator tools

- `read`, `edit`, `write`
- `schemabloc_list_snippets`
- `schemabloc_get_snippet`
- `schemabloc_render_snippet`
- `schemabloc_lookup_component`
- `schemabloc_lint_source`
- `png_inspect_image`
- `png_measure_bounds`
- `png_measure_regions`
- `png_normalize_geometry`
- `png_health`

### Reviewer tools

- `read`
- `schemabloc_lookup_component`
- `schemabloc_lint_source`
- `png_inspect_image`
- `png_measure_bounds`
- `png_measure_regions`
- `png_normalize_geometry`
- `png_health`

Reviewer remains read-only; do not add write tools or `png_trace`.

### Prompt requirements

Generator:

- use `sbEntree`, `sbBloc`, `sbComp`, `sbRelier`, `sbSortie` as the primary mechanism;
- preserve named nodes; do not auto-rename;
- use `sbRenvoi`, `sbRelierxy`, and `sbRelieryx` for feedback/branch links;
- use ordinary TikZ only for annotations or constructs schemabloc cannot express;
- measure target and render with the PNG tools before geometry claims;
- cite tool, raw box/point, basis, threshold/background, and warnings;
- do not embed the target image or trace it.

Reviewer:

- check block inventory, signal labels, summing signs, forward/feedback topology, link endpoints, and geometry;
- distinguish structural errors from visual polish;
- use `schemabloc_lint_source` for structural claims only;
- measure target and render for geometry findings;
- never edit files.

### Workflow documents

Add:

```text
workflow/control/objective.md
workflow/control/completion-criteria.md
workflow/control/coordinator.md
workflow/control/generator-instructions.md
workflow/control/reviewer-instructions.md
workflow/control/domain-rules.md
workflow/control/current-human-feedback.md
```

The coordinator can reuse the existing sequential generator-reviewer loop, persisting, rendering, validating, archiving, and decision rules, but with control paths and agents.

Add a skill:

```text
.omp/skills/schemabloc-diagram/SKILL.md
```

covering the macro catalog, measurement workflow, citation rule, and no-baseline policy.

---

## Phase 5 — Control-specific rendering and validation

### `scripts/control/render.sh` or profile-aware `render.sh`

- compile `current-control/reconstruction.tex` with `latexmk`/`pdflatex`;
- produce `current-control/reconstruction.pdf` and `.png`;
- fail if `schemabloc.sty` is unavailable.

### `scripts/control/validate.sh` or profile-aware `validate.sh`

Checks:

1. source exists and is non-empty;
2. `\usepackage{schemabloc}` present;
3. exactly one `tikzpicture`;
4. no `circuitikz` package/environment in the control profile;
5. no `\includegraphics`, `control_diagram.png`, or `target.png`;
6. braces and environments balanced;
7. every `sb*` link endpoint resolves;
8. duplicate node names absent;
9. required labels present;
10. PDF and PNG exist and are non-empty;
11. block/comparator/link inventory is reported;
12. warnings for manual rectangles and unknown `sb*` macros.

Write `current-control/validation-result.json` using the existing validation schema or a control-specific schema.

### Smoke test

Add `scripts/control-smoke.sh`:

- render a minimal schemabloc document;
- call `schemabloc_health`, list/render/lookup/lint routes;
- lint the corrected seed;
- compile a candidate and confirm PDF/PNG;
- verify no baseline tool/route exists.

---

## Phase 6 — Tests and acceptance

### Pharo tests

- `SchemablocSnippetCatalogTest`
- `SchemablocSnippetRenderTest`
- `SchemablocSourceScannerTest`
- `SchemablocLintRuleTest`
- `SchemablocToolsIntegrationTest`

Cover:

- all snippets render with minimal parameters;
- math braces/backslashes survive;
- unknown placeholders rejected;
- duplicate node names rejected;
- undefined link endpoints rejected;
- missing `schemabloc` package rejected;
- `\includegraphics` rejected;
- manual block rectangle warns;
- corrected seed passes the expected structural checks;
- optional `required_labels` works.

### MCP tests

- all `schemabloc_*` tools registered;
- module/tool filters hide them when excluded;
- agent allowlists contain exactly the intended tools;
- no `png_create_baseline` or `schemabloc` baseline tool.

### End-to-end acceptance

1. `schemabloc.sty` found and the corrected seed compiles.
2. Control profile paths and scripts work without touching circuit files.
3. `schemabloc_*` MCP tools are callable by Bash/eval-denied agents.
4. A control generator can render blocks, comparators, and links; lint the source; write `current-control/reconstruction.tex`.
5. `render.sh` produces PDF/PNG; `validate.sh` passes the structural checks.
6. The reviewer can measure both target and render and accept/revise with cited geometry.
7. The circuit workflow remains green.
8. The shared `DsktService.image` contains both `ctikz` and `schemabloc` providers.
9. `check-workspace.sh --profile control` passes (including `kpsewhich schemabloc.sty`).
10. No baseline feature is reintroduced.

---

## Recommended sequencing

1. Install TeX + `schemabloc`; compile and correct the seed.
2. Add profile paths and script parameterization; keep circuit default working.
3. Add `Schemabloc-Core` catalog/renderer/scanner/lint and tests.
4. Add MCP tools, schemas, and shared-image loading.
5. Add control agents and workflow documents.
6. Add control validation/rendering/smoke.
7. Run end-to-end and tune offsets using PNG measurements.

The main risks are the missing TeX toolchain, the rough seed’s incomplete topology, and the temptation to reuse CircuitTikZ validation rules. The first two are blocking; the third would make the control loop accept structurally wrong schemabloc output.
