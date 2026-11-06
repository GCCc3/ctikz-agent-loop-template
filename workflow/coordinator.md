# Coordinator protocol

Execute a sequential Generator-Reviewer loop. The Generator and Reviewer must
never run concurrently.

This protocol covers the reconstruction loop only. The efficiency analysis in
`workflow/efficiency-analysis.md` is human-initiated: never invoke it, never
schedule it, and never treat its proposals as instructions.

## Before the first iteration

1. Run `scripts/init-current.sh`.
2. Run `scripts/check-workspace.sh`.
3. Read `workflow/completion-criteria.md` and determine the next iteration
   number with `scripts/next-iteration-number.sh`.
4. If the maximum number of iterations has already been reached, stop with
   status `iteration-limit-reached`.

## One iteration

1. Delegate one pass to the `diagram-generator` subagent.
2. Wait for terminal completion. Do not start review while generation is active.
3. Write the exact structured Generator result to
   `tmp/generation-result.candidate.json`.
4. Persist it atomically:

   ```bash
   scripts/persist-result.sh \
     tmp/generation-result.candidate.json \
     current/generation-result.json \
     schemas/generation-result.schema.json
   ```

5. If generation returned `blocked` or `failed`, stage the transcripts (step 11)
   and archive the iteration, then stop.
6. Run `scripts/render.sh`. A rendering failure is evidence for validation and
   review; do not fabricate a rendered image.
7. Run `scripts/validate.sh`. It writes
   `current/validation-result.json`, including when checks fail.
8. Delegate one pass to the `diagram-reviewer` subagent only after generation,
   persistence, rendering, and validation have settled.
9. Write the exact structured Reviewer result to
   `tmp/review-result.candidate.json`.
10. Persist it atomically:

    ```bash
    scripts/persist-result.sh \
      tmp/review-result.candidate.json \
      current/review-result.json \
      schemas/review-result.schema.json
    ```

11. Stage the subagent transcripts for this iteration, keeping the Generator and
    Reviewer transcripts in separate directories:

    ```bash
    mkdir -p tmp/transcripts/generator tmp/transcripts/reviewer
    cat history://<generator-agent-id> \
      > tmp/transcripts/generator/NN-<generator-agent-id>.md
    cat history://<reviewer-agent-id> \
      > tmp/transcripts/reviewer/NN-<reviewer-agent-id>.md
    ```

    Prefix each file with a short front-matter block recording `iteration`,
    `role`, `agent`, `agentKind`, `agentStatus`, `resultArtifact`, and `source`.
    Every subagent that touched the iteration gets a file, including discarded
    or cancelled ones; order them with an `NN` prefix. `history://` resolves
    only in a direct shell command, never inside a script, so the coordinator
    stages these files itself. `scripts/archive-iteration.sh` copies
    `tmp/transcripts/` into the archive and clears the staging directory after
    a successful archive.

12. Run `scripts/archive-iteration.sh` regardless of whether the decision is
    `accept`, `revise`, `human-review`, or `blocked`.
13. Apply the decision rules below.

## Decision rules

### `accept`

Accept only if all of these hold:

- `current/validation-result.json` has status `passed`;
- the Reviewer returned `accept`;
- there are no critical or major findings;
- the accepted iteration was archived.

Report the evidence and finish the goal.

### `revise`

Start another iteration only if the iteration limit has not been reached. The
next Generator must read the current review and validation result.

### `human-review`

Pause automatic iteration. Ask exactly the question in `humanQuestion` and
explain where the relevant images and archive are located. When feedback is
supplied, record it faithfully in `workflow/current-human-feedback.md`, then
start a new iteration. Do not reinterpret or weaken the feedback.

### `blocked`

Stop and report the blocker. Preserve current files and the archive. Do not
invent missing evidence or silently change the objective.

## Failure and retry rules

- Do not retry an identical failing action indefinitely.
- A malformed structured result must not be persisted.
- If a subagent times out or terminates without valid output, archive available
  evidence and stop with the failed phase identified.
- A failed deterministic check can lead to `revise`; it can never lead to
  `accept`.
- Candidate files under `tmp/` are not authoritative state.
- Files under `iterations/` are immutable and must never be edited after
  archival.
