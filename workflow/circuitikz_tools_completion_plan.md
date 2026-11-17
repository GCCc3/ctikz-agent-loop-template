# CircuitTikZ tools — completion plan

Status: implemented.

Scope: close every gap found in the review of `workflow/circuitikz_tools_implementation_plan.md`. Phase 0 and Phase 1 are release blockers.

## Phase 0 — Shared path containment and server configuration

### W0.1 — One symlink-aware path resolver

- Add `Dskt-Core/DsktPathResolver.class.st`:
  - `resolveExisting: aPath under: aRoot` and `resolveWritable:under:`.
  - Resolve symlinks and `..`; do **not** rely on `FileReference>>canonicalize` alone — the probe proved it accepts a symlink escaping the root.
  - Accept only if the resolved path is the root itself or begins with `root pathString , separator`; compare resolved paths, not raw strings.
  - Return structured `path_outside_repo`, `source_not_found`, or `output_path_rejected`.
- Replace the prefix checks in:
  - `CtikzLintService>>resolvePath:`
  - `DsktSettings>>traceLog`
  - `PngMeasureService>>imageAbsolutePathFor:`
  - `PngMeasureService>>outputDirectory:` and `writeBytes:to:request:`
- Tests: symlink inside → outside, sibling directory sharing the root prefix, `../`, absolute path, missing file, directory, and valid in-root file. Use `CtikzLintService` and `PngMeasureService` fixtures.

### W0.2 — Wire `DSKT_HOST`

- Add `DsktSettings>>bindAddress` that parses `DSKT_HOST` (`127.0.0.1`, `0.0.0.0`, dotted IPv4), rejects invalid values, and returns the Teapot bind address.
- Change `DsktServer>>initialize` from hardcoded `#[127 0 0 1]` to the parsed address.
- Test: default loopback; explicit loopback; invalid host raises a startup error.

### W0.3 — Health/error handling

- Wrap `/health`, `/png/health`, and `/ctikz/health` provider calls in `handleHealth:` error handling; return the shared error envelope with a valid status instead of an uncaught exception.
- Add `catalog_unavailable` to `CtikzRouteProvider>>statusFor:`; map to 500 (or 503, documented).
- Test a dummy provider whose `health` raises, plus an invalid catalog.

## Phase 1 — Deployment and lifecycle

### W1.1 — Make install reproducible

- Fix `scripts/dskt-install.sh`:
  - Ensure the default `DSKT_IMAGE` parent exists; fail with a clear message when `DSKT_BASE_IMAGE` is absent. The default image is `tmp/dskt/DsktService.image`.
  - On this workstation, the base image is `/home/codespace/moose13-base/Moose13-stable-Pharo64-14/Moose13-stable-Pharo64-14.image` and the VM wrapper is `/home/codespace/moose13/pharo`. Set `DSKT_BASE_IMAGE` and `PHARO` accordingly. The image is a Pharo 14 Moose image and already contains Teapot, Beacon, and NeoJSON. It is not currently running, so its `.changes` file can be copied safely.
  - Load `BaselineOfDskt`, `BaselineOfPngDiagramMeasure`, `BaselineOfCtikzTools` in that order.
  - Resolve the observed Beacon reload failure (`Improper store into indexable object`): pin Beacon to a compatible commit, avoid reloading already-loaded dependencies, or use a base image with dependencies preloaded.
  - After loading, assert `CtikzSnippetCatalog default validationWarnings isEmpty` and `DsktRouteRegistry current providers` contains `png` and `ctikz` before snapshotting.
  - Snapshot and quit only after those assertions pass.
- Add a non-snapshot `--check` mode or `scripts/ctikz-tools-status.sh` that prints providers, catalog version, lint rule version, and image path.

### W1.2 — Rebuild the saved image

- Run the fixed install script against the actual base image.
- Verify after reboot: `DsktServer` starts, `/health` reports both services, `/ctikz/health` reports `catalog_status: "valid"`, and `/png/health` remains green.
- Confirm no duplicate routes or trace loggers after a second startup.

### W1.3 — Make start/smoke scripts consistent

- Fix `scripts/dskt-start.sh` and `scripts/png-measure-install.sh` stale “PDM service” messages and missing-default-image guidance.
- Extend `scripts/ctikz-tools-smoke.sh` to assert:
  - `ctikz_health` fields;
  - trace enrichment fields;
  - lint default path;
  - error-code/status pairs for path escape and snippet-not-found.
- Run the smoke script against the rebuilt server, then rerun after a snapshot/reboot.

## Phase 2 — Catalog correctness

### W2.1 — Duplicate ids

- In `CtikzSnippetCatalog>>reload`, collect ids and fail with `snippet_validation_failed` when any id repeats.
- Add `testDuplicateIdFailsCatalog`.

### W2.2 — Real component lookup

- Add `CtikzSettings` or a `DSKT_CIRCUITIKZ_STY` setting for the installed `circuitikz.sty` path.
- Add `CtikzComponentIndex` that parses the installed style (or a generated manifest) for component/style declarations, aliases, and defaults.
- Make `CtikzComponentLookup` load from that index instead of the hardcoded dictionary, with a bundled fallback manifest for tests and missing TeX Live.
- Populate `CtikzComponentInfo`: `description`, `declaration`, `aliases`, `defaultLength`, `defaultHeight`, `styleDefaults`, `circuitikzVersion`.
- Validate catalog component/style keys against the index during load; unknown keys are `snippet_validation_failed`.
- Tests: `L` → inductor, `R` → resistor, `generic` → generic bipole, `sV` → independent voltage source; declaration line present; unknown key rejected; missing style file reports degraded health, not a crash.

### W2.3 — Reject target-specific default values

Policy note: the original plan's token checks for `gfm`, `target`, and `reconstruction` in ids, titles, descriptions, and tags are dropped. Do not add them.

- Extend `CtikzSnippetValidator` to reject:
  - default string values `L_f`, `R_f`, `Z_g`, `GFM converter`, `grid`;
  - numeric defaults for `x`, `y`, `x0`, `y0`, `x1`, `y1`;
  - default `text` values on `label/generic`.
- Test that the current catalog passes and a constructed `label/generic` with `text` default `L_f` fails.

### W2.4 — Render-time placeholder validation

- Extract placeholder scanning into `CtikzSnippetValidator>>validatePlaceholders:`.
- Call it from `CtikzSnippetRenderer>>render:parameters:` before Mustache; reject unresolved `{{...}}` after rendering.
- Test unknown placeholder and malformed/unclosed Mustache both fail with `snippet_validation_failed` or `template_render_failed`.

### W2.5 — Presets and enum

- Validate preset keys: a preset key absent from the schema is allowed (caller cannot override); a preset key present in the schema must equal its default.
- Enforce `enum` for defaults and rendered values.
- Add tests for preset override rejection and enum rejection.

### W2.6 — Valid minimal bipole

- Make `component/bipole`’s `component_options` required, or default it to a valid key such as `generic`; do not emit `to[]`.
- Update `testAllSnippetsRenderWithMinimalParameters` to supply the required value.

### W2.7 — Sorted catalog version

- Sort snippet dictionaries by `id` before hashing in `CtikzSnippetCatalog>>computeCatalogVersion`.
- Test that load order does not change the version and that reload is idempotent.

## Phase 3 — Lint correctness

### W3.1 — Verbatim and unsupported constructs

- Extend `CtikzSourceScanner` to recognize `\begin{verbatim}`, `\begin{lstlisting}`, and `\verb|...|`.
- Mask verbatim contents from forbidden-token, brace, environment, and coordinate checks while preserving line numbers.
- Populate `CtikzSourceModel>>unsupported`.
- Add `CtikzUnsupportedConstructRule` (id `unsupported_construct`, default `warning`) and include it in the rule list.
- Test: `\includegraphics` inside verbatim produces `unsupported_construct: warning` and `no_image_inclusion: passed`.

### W3.2 — Ambiguous coordinates

- Extend `coordinateReferencesIn:` to record `+` and `++` relative references and `$(...)`/`calc` expressions separately.
- Update `CtikzAmbiguousCoordinatesRule` to warn for all four forms; keep `defined_coordinates` from treating them as direct names.
- Add fixtures for `+ (1,0)`, `++ (1,0)`, `$(a)+(1,0)$`, and `calc`.

### W3.3 — Default lint path

- In `dskt_mcp_server/server.py`, default `path` to `current/reconstruction.tex` when neither `path` nor `source_text` is supplied; keep the server’s exactly-one-input rule.
- Add a test for `ctikz_lint_source()` with no arguments.

### W3.4 — Request typing and size checks

- Validate in `CtikzLintService`:
  - `path` is a string;
  - `source_text` is a string;
  - `required_labels` and `forbid_patterns` are collections of strings;
  - `strict` is a boolean.
- Return `invalid_request` for wrong types, not `internal_error`.
- Check file size with `FileReference>>size` before reading; keep the `source_text` byte cap.
- Add tests for each wrong type and an oversize file.

### W3.5 — Use or remove `CtikzLintReport`

- Make `CtikzLintService>>lintSource:` return `CtikzLintReport` data (add `sourceKind`/`sourcePath` accessors and `asDictionary`), or delete the unused class. Prefer using it so the declared model is real.
- Add a report-shape test asserting the existing envelope keys.

### W3.6 — Rule versioning

- Add `CtikzLintRule>>version` (default 1) and hash `id`, `version`, and `defaultSeverity` in `CtikzLintService>>rulesVersion`.
- Add a test that changing a rule version changes `lint_rules_version`.

## Phase 4 — Trace, HTTP, and determinism

### W4.1 — Ctikz trace details

- Replace `details: nil` in `CtikzRouteProvider>>installRoutesOn:` with detail blocks:
  - catalog/list/get/render/lookup: `tool_family: 'catalog'`, `catalog_version`, `snippet_id` where applicable;
  - lint: `tool_family: 'lint'`, `source_path`, `check_counts` from `summary`, `lint_rules_version`.
- Add `CtikzTraceTest` asserting the fields are populated and that results/checksums are unchanged.
- Align `_trace_line` in the MCP shim with the same generic fields.

### W4.2 — HTTP status and health

- Add tests for every route: success, `invalid_request`, `path_outside_repo`, `source_not_found`, `source_too_large`, `unsupported_encoding`, `snippet_not_found`, `unknown_parameter`, `missing_parameter`, `invalid_parameter`, `snippet_validation_failed`, `catalog_unavailable`, `internal_error`.
- Verify lint failures still return HTTP 200.
- Verify `/ctikz/health` cannot crash the server when the catalog is invalid.

### W4.3 — Deterministic unknown-component suggestions

- Sort `knownComponents keys` before returning `suggestions`.
- Add a determinism test for unknown lookup output.

## Phase 5 — MCP and workflow

### W5.1 — Agent allowlists

- Add to `.omp/agents/diagram-generator.md`:
  - `ctikz_list_snippets`, `ctikz_get_snippet`, `ctikz_render_snippet`, `ctikz_lookup_component`, `ctikz_lint_source`.
- Add to `.omp/agents/diagram-reviewer.md`:
  - `ctikz_lookup_component`, `ctikz_lint_source`.
- Add `dskt_health` where useful; keep `read`/`edit`/`write` as appropriate.
- Verify with an agent run that Bash/eval-denied subagents can call exactly those tools and not the excluded ones.

### W5.2 — MCP test coverage

- Add `tests/test_core.py`: `repo_root`, `trace_log`, `service_url`, `resolve_image_path` inside/outside, envelope success/error.
- Add `tests/test_client.py`: `get_json`/`post_json` with `httpx.MockTransport`; transport error, non-JSON, error envelope, trace-line best effort.
- Extend `tests/test_server.py`: `register_tools` with a fake MCP, module filter, explicit tool filter, annotations, excluded tools absent.
- Add a real FastMCP `list_tools`/call test if practical.

### W5.3 — Remove the old PNG MCP shim

- Delete `tools/png-measure/mcp` (or archive it outside the repo) and its `uv.lock`, `pyproject.toml`, and tests.
- Update root README and any scripts that reference `png_diagram_measure_mcp_server`.
- Add a repository scan test/grep gate for `PmdtServer`, `PDMT_`, and the old MCP package.

## Phase 6 — Hardening suite

Add the missing tests from the plan’s Phase 4/§8:

- `DsktServerLifecycleTest`: start/stop, duplicate start, no duplicate routes/loggers, `/health` with zero domains.
- `DsktCoreIsolationTest`: load `Dskt-Core` alone; dummy provider route; no domain imports.
- `CtikzCatalogPolicyTest`: duplicate id, unknown component, target-specific default values, preset override, enum, label anchor spacing; no token checks for `gfm`, `target`, or `reconstruction`.
- `CtikzLintEdgeTest`: verbatim, `+`, `$(...)`, custom required labels, missing-label line numbers.
- `CtikzPathTest`: symlink, sibling prefix, `..`, absolute, directory, oversize file.
- `CtikzHttpApiTest`: envelope/status matrix, lint failures still 200.
- `CtikzTraceTest`: one line per render/lookup/lint, health/listing untraced, `check_counts` correct.
- `CtikzConcurrencyTest`: parallel render/lint, catalog state intact, trace lines not corrupted.
- `CtikzDeterminismTest`: identical render checksums, identical lint JSON bytes, sorted suggestions.
- MCP filter/allowlist test: `DSKT_MODULES=ctikz_lint` exposes only lint; `DSKT_TOOLS=ctikz_lint_source` exposes one; excluded calls fail.

## Phase 7 — Docs and cleanup

- Update `workflow/circuitikz_tools_implementation_plan.md`: change `Status: proposal (not implemented)` to the actual state and link this completion plan.
- Rewrite `workflow/png_measurement_operational_steps.md` to `DsktServer`, `PngMeasureRouteProvider`/`PngMeasureService`, `DSKT_*`, `PNG_*`, and `/png/*`; or mark it historical and point to the current README.
- Add `tools/png-measure/README.md` with env vars, routes, and trace path, or fix the root README link.
- Fix stale `PDM` wording in `scripts/png-measure-install.sh` and `scripts/dskt-start.sh`.
- Remove dead code: unused `CtikzLintReport` path if W3.5 deletes it; old PNG MCP package; any unused `PDMT_*` references.
- Run the full test matrix and commit the completed work.

## Exit criteria

The plan is complete when all of these pass:

1. `Ctikz-*`, `Dskt-*`, and `PngDiagramMeasure-*` SUnit suites are green.
2. `tools/dskt/mcp` tests cover core, client, server, filters, and annotations.
3. `scripts/dskt-install.sh` snapshots an image; after reboot `/health` lists `png` and `ctikz`, and `/ctikz/health` is valid.
4. `scripts/ctikz-tools-smoke.sh` passes against the rebuilt server.
5. Symlink, sibling-prefix, `..`, absolute, and oversize path tests all fail closed.
6. Ctikz trace lines contain `tool_family`, `snippet_id`/`source_path`, `check_counts`, `catalog_version`, and `lint_rules_version`.
7. Catalog rejects duplicate ids, unknown components, target-specific default values, preset overrides, enum violations, and unknown render placeholders. It does not reject ids, titles, descriptions, or tags merely for containing `gfm`, `target`, or `reconstruction`.
8. Lint handles verbatim/unsupported constructs, `+`/`$(...)` ambiguity, default path, typed inputs, and pre-read size limits.
9. Agent allowlists expose exactly the intended MCP tools; excluded tools are not callable.
10. `grep` finds no `PmdtServer`, `PDMT_`, or old PNG MCP package in code, scripts, config, or README.
