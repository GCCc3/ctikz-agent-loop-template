# CircuitTikZ Generator-Reviewer Loop for omp

This project is a complete, filesystem-based template for reconstructing an
image of an electrical diagram as editable LaTeX source using CircuitTikZ.

The division of responsibility is deliberate:

- **Smalltalk or another project generator** creates and specializes the text
  files in this directory.
- **omp** coordinates the Generator and Reviewer subagents.
- **Shell scripts** perform deterministic rendering, validation, persistence,
  and archival.
- **The filesystem** stores the active iteration and immutable iteration
  history.
- **A human** supplies the target image, reviews ambiguous results, and may add
  feedback between iterations.

## Prerequisites

Install and configure:

1. `omp`, with at least one authenticated model provider;
2. Bash;
3. Python 3;
4. a LaTeX distribution containing CircuitTikZ;
5. either `latexmk`, `lualatex`, or `pdflatex`;
6. either `pdftoppm` or ImageMagick `magick` for PDF-to-PNG conversion;
7. `uv` for the PNG measurement MCP server;
8. a Pharo 13.1 image and VM for the PNG measurement service (optional, only when
   the measurement tools are used).

The scripts do not download packages or modify the host installation.

## Supply the target image

Copy the electrical diagram to reconstruct to:

```text
reference/target.png
```

The target is intentionally absent from this archive because it is the input
for a particular reconstruction task. See `reference/README.md`.

## Configure models

The agents inherit the model selected by the parent omp session by default.
To assign different models to generation and review:

1. edit `.omp/config.yml` and uncomment the `modelRoles` block;
2. edit `.omp/agents/diagram-generator.md` and uncomment
   `model: "@generator"`;
3. edit `.omp/agents/diagram-reviewer.md` and uncomment
   `model: "@reviewer"`;
4. replace the example model selectors with selectors reported by `omp models`.

## Initialize and check the workspace

```bash
scripts/init-current.sh
scripts/check-workspace.sh
```

`init-current.sh` copies `input/initial-reconstruction.tex` into `current/`
without overwriting an existing reconstruction.

## PNG measurement tool (optional)

The generator and reviewer can call typed PNG measurement tools through MCP.
The tools inspect a PNG, build an ink mask, measure canvas and ink bounds,
measure named regions, convert geometry between bases, and build a deterministic
baseline document. They do not identify electrical components.

One-time install into a dedicated Pharo image:

```bash
export PHARO="$HOME/pharo-launcher/pharo-vm/pharo"
export PDMT_BASE_IMAGE="$HOME/Pharo/images/Pharo13.1/Pharo13.1.image"
scripts/png-measure-install.sh
```

The install script loads `PngDiagramMeasure`, registers `PmdtServer` in the image
startup list, and snapshots. The start script runs the saved image once per boot;
do not reload the Pharo code per reconstruction iteration:

```bash
scripts/png-measure-start.sh
```

The measurement service listens on `127.0.0.1:8087` by default. It is local-only
and unauthenticated; do not expose it. `.omp/mcp.json` starts the Python shim
with `uv`; the shim forwards typed JSON to the Pharo service and preserves the
response envelope even on 4xx/5xx.

The trace log records one JSON line per measurement call:

```bash
tail -f tmp/png-measure/tool-trace.jsonl
curl -s 'http://127.0.0.1:8087/png/trace?limit=50'
```

`png_trace` is diagnostic only. It is not measurement evidence and is not part of
the reconstruction loop. See `tools/png-measure/README.md` for environment
variables, routes, and promotion of `reference/target.measurements.json`.

## Start the workflow

```bash
scripts/run.sh
```

This starts an interactive omp session with the coordinator and objective
attached. Inside omp, the workflow may also be started as a bounded goal:

```text
/goal Execute the workflow in workflow/coordinator.md until it is accepted,
human input is required, a blocker occurs, or the iteration limit is reached.
/goal budget 120000
```

The exact budget is a project decision, not a success criterion.

## Human feedback

When omp asks for a human decision, edit:

```text
workflow/current-human-feedback.md
```

Preserve the heading and replace the body with concrete feedback. Then tell the
coordinator to archive the feedback with the next iteration and continue.

## Active files

The workflow writes active artifacts under `current/`:

```text
current/reconstruction.tex
current/reconstruction.pdf
current/reconstruction.png
current/generation-result.json
current/validation-result.json
current/review-result.json
```

Candidate structured results are first written under `tmp/`, validated, and
atomically promoted with `scripts/persist-result.sh`.

## Iteration archives

Each completed, failed, blocked, or human-paused iteration is archived under:

```text
iterations/iteration-NNN/
```

Archives contain the source, rendered artifacts, structured results, workflow
instructions, human feedback, logs, subagent transcripts, and a validated
manifest. The archive script refuses to overwrite an existing iteration.

Subagent transcripts are stored per role:

```text
iterations/iteration-NNN/transcripts/generator/NN-<agent-id>.md
iterations/iteration-NNN/transcripts/reviewer/NN-<agent-id>.md
```

Each file opens with front matter recording the iteration, role, agent id, agent
kind, agent status, the structured result it produced (if any), and its
`history://` source. Every agent that touched the iteration is included, so a
discarded or cancelled pass stays visible. The coordinator stages them under
`tmp/transcripts/` before archiving, because `history://` resolves only in a
direct shell command and not inside a script; `scripts/archive-iteration.sh`
copies the staged tree into the archive and clears it afterwards.

Transcript bodies are the agent-level record: prompts, assistant messages, tool
calls with result sizes, and the final structured output. Tool result bodies and
model-internal reasoning are not part of the record. Iteration folders that were
archived before this layout existed were backfilled from the same source.

The coordinating session's own transcript is saved at
`session-transcript.md`, so the decisions that drove the loop stay
readable after the session process is gone.

## Efficiency analysis (human-initiated)

A second workflow, `workflow/efficiency-analysis.md`, studies the loop itself
rather than the diagram. It is never part of the reconstruction loop and runs
only when a human asks for it.

```text
workflow/efficiency-analysis.md      gated protocol: evidence rules, one pass
.omp/agents/efficiency.md            read-only analyst subagent
schemas/efficiency-report.schema.json  validated report shape
scripts/render-efficiency-report.py  JSON -> deterministic Markdown
analysis/efficiency-through-NNN.md   human-readable report (generated)
analysis/efficiency-through-NNN.json validated structured report
analysis/efficiency-through-NNN.transcript.md  analyst transcript
```

The `efficiency` subagent reads every archived transcript plus the current
source and the existing tooling, then reports patterns with per-occurrence
evidence, separates tool-shaped repetition from judgement work, and specifies
each candidate MCP tool with a model-facing description, typed inputs, expected
savings, and risks. Nothing it proposes is applied automatically.

Ask for a pass explicitly, for example:

```text
Run workflow/efficiency-analysis.md over the archived iterations.
```

## Manual deterministic commands

```bash
scripts/render.sh
scripts/validate.sh
scripts/archive-iteration.sh
```

`render.sh` produces PDF and PNG artifacts. `validate.sh` writes a structured
validation result and exits nonzero when checks fail. The coordinator must not
interpret a nonzero validation exit as a script crash if
`current/validation-result.json` was produced and is valid.

## Security boundary

The Generator may read and modify text files but has no Bash tool. The Reviewer
is read-only. The parent coordinator owns shell execution and persistence.
Review `.omp/config.yml` before use, particularly approval rules and command
allowlists. Run the workflow in a repository or directory dedicated to the
reconstruction task.
