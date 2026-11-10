# PNG Measurement Tool — Remaining Operational Steps

Status: the Pharo source, MCP shim, scripts, schemas, and skill are committed.
The tool is **not yet operational** in this environment. The installed image
lacks the classes, the service is not running, the baseline is not promoted, and
the agents do not reference the tool. This document lists the concrete steps
needed to close those gaps.

Verified environment facts (2026-11-10):

- Pharo VM: `/home/codespace/moose13/pharo`
- Base image: `/home/codespace/moose13/Pharo.image` (Pharo 14.0.0SNAPSHOT)
- Existing image: `/home/codespace/moose13/PngMeasure.image`
- Repo: `/workspaces/ctikz-agent-loop-template`
- `pharo` is not on `PATH`; always set `PHARO` explicitly.
- The image at `/home/codespace/moose13/PngMeasure.image` does **not** contain
  `PmdtServer` or `PmdtService`.
- No service is listening on 8087 or 18087.
- `tmp/png-measure/tool-trace.jsonl` and `tmp/png-measure/baseline.json` exist
  from a prior in-memory run; they are not evidence that the saved image works.

## 1. Fix the `showln:` incompatibility (blocker)

`PharoDebug.log` shows `NonInteractiveTranscript did not understand #showln:`
from `PDMT READY 18087`. Pharo 14.0.0 does not provide `Transcript showln:`;
the plan targets Pharo 13.1. Either use a Pharo 13.1 base image or patch the
three call sites to `Transcript show: '...'; cr`.

Files to change:

- `tools/png-measure/pharo/src/PngDiagramMeasure-Core/PmdtServer.class.st:43`
- `tools/png-measure/pharo/src/PngDiagramMeasure-Core/PmdtToolTrace.class.st:32`
- `tools/png-measure/pharo/src/PngDiagramMeasure-Core/PmdtTraceLogger.class.st:88`

Acceptance: a headless boot on the chosen base image reaches `startUp:` without
a `MessageNotUnderstood`.

## 2. Install the package into a saved image

The install script loads Tonel, registers `PmdtServer` in the image startup
list, and snapshots. It must run against a stopped image.

```bash
export PHARO=/home/codespace/moose13/pharo
export PDMT_REPO_ROOT=/workspaces/ctikz-agent-loop-template
export PDMT_BASE_IMAGE=/home/codespace/moose13/Pharo.image
export PDMT_IMAGE=/workspaces/ctikz-agent-loop-template/tmp/png-measure/PngMeasure.image
export PDMT_PORT=8087
export PDMT_HOST=127.0.0.1
export PDMT_OUTPUT_ROOT=/workspaces/ctikz-agent-loop-template/tmp/png-measure
export PDMT_TRACE_LOG=$PDMT_OUTPUT_ROOT/tool-trace.jsonl

scripts/png-measure-install.sh
```

If `PDMT_IMAGE` already exists, the script uses it instead of copying the base.
The current `/home/codespace/moose13/PngMeasure.image` is not installed; either
point `PDMT_IMAGE` at it and install in place, or use the default repo-local
path above.

Acceptance: `PmdtServer` and `PmdtService` are present in the saved image, and
`Smalltalk startUpList includes: PmdtServer` is true after reopening the image.

## 3. Start the service

The saved image must run as a long-lived process. Do not reload the Pharo code
per reconstruction iteration.

```bash
scripts/png-measure-start.sh
```

The script sets `PDMT_AUTOSTART=1` and execs the VM headless. The startup hook
starts Teapot on `PDMT_PORT`. Default is 8087. A prior run used 18087; choose
one port and use it consistently for the server, the smoke script, and the MCP
shim.

Acceptance:

```bash
curl -s http://127.0.0.1:8087/png/health
```

returns `{"success":true,...}` and reports the trace status.

## 4. Run the smoke test

With the service running:

```bash
PDMT_PORT=8087 scripts/png-measure-smoke.sh
```

It exercises health, inspect, mask, bounds, regions, geometry, baseline, trace,
malformed JSON (expects 400), and path escape (expects 400).

Acceptance: script prints `smoke ok`. If a route returns 500, check
`PharoDebug.log` and `tmp/png-measure/tool-trace.jsonl`.

## 5. Generate and promote the baseline

The smoke script writes `tmp/png-measure/target.baseline.json` via the
`create_baseline` route. Promote it into `reference/`:

```bash
scripts/promote-baseline.sh
```

This validates the document against `schemas/png-measurement.schema.json` and
copies it to `reference/target.measurements.json`.

Acceptance: `reference/target.measurements.json` exists, its
`image.sha256` matches `sha256sum reference/target.png`, and its
`baseline_sha256` is 64 hex characters. Re-running `create_baseline` must
produce byte-identical output.

Note: `scripts/promote-baseline.sh` is not currently listed in
`scripts/check-workspace.sh`. Add it there so the workspace check covers it.

## 6. Write `tools/png-measure/README.md`

`README.md` points to this file for environment variables, routes, and baseline
promotion. It is missing. Create it with:

- the environment variable table (`PDMT_PORT`, `PDMT_HOST`, `PDMT_OUTPUT_ROOT`,
  `PDMT_TRACE_LOG`, `PDMT_MAX_PIXELS`, `PDMT_TRACE_ENTRIES`,
  `PDMT_TRACE_MAX_BYTES`, `PDMT_AUTOSTART`, `PDMT_DEBUG`, `PDMT_REPO_ROOT`);
- the six route names and their request fields;
- the trace surfaces (JSONL, `/png/trace`, `png_trace`) and rotation behavior;
- the install/start/smoke/promote lifecycle;
- the Pharo version actually used.

Acceptance: the README contains no stale Pharo 13.1 requirement if the image
remains 14.0.0.

## 7. Verify the MCP shim and its port

`.omp/mcp.json` starts the shim with `uv --directory tools/png-measure/mcp run
png-diagram-measure-mcp-server` and passes `${PDMT_PORT:-8087}`. Two checks:

1. Confirm omp expands `${...:-...}` in `mcp.json`. If it does not, replace the
   placeholders with literal values (`8087`, `127.0.0.1`, absolute repo path).
2. Run the shim against the live service and call every tool. A direct check:

```bash
cd tools/png-measure/mcp
PDMT_PORT=8087 PDMT_REPO_ROOT=/workspaces/ctikz-agent-loop-template \
PDMT_OUTPUT_ROOT=/workspaces/ctikz-agent-loop-template/tmp/png-measure \
uv run python - <<'PY'
import asyncio
from png_diagram_measure_mcp_server.server import mcp
async def main():
    print([t.name for t in await mcp.list_tools()])
asyncio.run(main())
PY
```

Acceptance: eight tools listed; `png_health` and `png_inspect_image` return the
Pharo envelope; a pre-dispatch rejection appears in the JSONL with
`phase:"mcp"`.

## 8. Integrate the tool into the agent prompts

Phase 3 of the plan requires updating the generator and reviewer prompts with
the measurement workflow and citation rule. Currently neither
`.omp/agents/diagram-generator.md` nor `.omp/agents/diagram-reviewer.md`
references the MCP tools. Add the relevant calls, the read-only boundary for the
reviewer, and the citation rule (tool, raw box, threshold, background, basis,
warning codes).

Acceptance: an agent without Bash or `eval` can call `png_measure_bounds` and
cite its result in a review.

## 9. Run the end-to-end workflow

Only after steps 1–8:

```bash
scripts/run.sh
```

The coordinator/renderer loop should now be able to call the measurement tools
during generation and review. Confirm `tmp/png-measure/tool-trace.jsonl` grows
with `phase:"server"` entries and `by_tool` counts in `/png/trace` reflect the
agent calls.

## 10. Operational hygiene

- Stop the service before reinstalling: a running image cannot be reopened by a
  second VM. `pgrep -f PngMeasure.image` must return nothing before
  `scripts/png-measure-install.sh`.
- Keep the trace log and baseline under `tmp/png-measure/` (gitignored).
  Do not commit absolute paths or trace data.
- Do not expose the service; it is unauthenticated and binds loopback.
- The supervisor process `pdm-test-server` failed with exit code 1. Its
  configuration is not in the repository. Fix or replace it with
  `scripts/png-measure-start.sh`; ensure its port matches the shim and that it
  does not start a second copy of the same image.
- If the image also hosts `SisServer`, both startup entries run on boot; keep
  `PDMT_PORT` (8087) and `PHARO_SIS_PORT` (8086 or configured) distinct.
