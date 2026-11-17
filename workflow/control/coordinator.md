# Control coordinator protocol

Execute a sequential Generator-Reviewer loop for the schemabloc control diagram.
The Generator and Reviewer must never run concurrently.

## Before the first iteration

1. Run `scripts/control/init-current.sh`.
2. Run `scripts/control/check-workspace.sh`.
3. Read `workflow/control/completion-criteria.md` and determine the next
   iteration number with `scripts/control/next-iteration-number.sh`.

## One iteration

1. Delegate one pass to the `control-generator` subagent.
2. Wait for terminal completion. Do not start review while generation is active.
3. Write the exact structured Generator result to
   `tmp/control/generation-result.candidate.json`.
4. Persist it atomically:

   ```bash
   scripts/persist-result.sh \
     tmp/control/generation-result.candidate.json \
     current-control/generation-result.json \
     schemas/generation-result.schema.json
   ```

5. If generation returned `blocked` or `failed`, stage the transcripts and
   archive the iteration, then stop.
6. Run `scripts/control/render.sh`. A rendering failure is evidence for
   validation and review.
7. Run `scripts/control/validate.sh`. It calls `schemabloc_lint_source`, writes
   `current-control/validation-result.json`, and fails closed if lint is
   unavailable.
8. Delegate one pass to the `control-reviewer` subagent only after generation,
   persistence, rendering, and validation have settled.
9. Write the exact structured Reviewer result to
   `tmp/control/review-result.candidate.json`.
10. Persist it atomically:

    ```bash
    scripts/persist-result.sh \
      tmp/control/review-result.candidate.json \
      current-control/review-result.json \
      schemas/review-result.schema.json
    ```

11. Stage the subagent transcripts under `tmp/control/transcripts/generator`
    and `tmp/control/transcripts/reviewer`.
12. Run `scripts/control/archive-iteration.sh`.
13. Apply the decision rules below.

## Decision rules

### `accept`

Accept only if all of these hold:

- `current-control/validation-result.json` has status `passed`;
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
supplied, record it faithfully in `workflow/control/current-human-feedback.md`,
then start a new iteration.

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
- Files under `iterations-control/` are immutable after archival.