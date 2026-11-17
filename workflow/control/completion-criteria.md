# Completion criteria

The workflow succeeds only when all conditions below hold:

1. `current-control/reconstruction.tex` exists and is non-empty.
2. `schemabloc` is the primary block-diagram mechanism.
3. The document compiles successfully.
4. `current-control/reconstruction.pdf` and `.png` exist and are non-empty.
5. `scripts/control/validate.sh` reports `passed`, including a
   `schemabloc_lint_source` result with zero failed checks.
6. The Reviewer returns `accept`.
7. The review contains no critical or major findings.
8. The latest human feedback, if any, has been addressed.
9. The accepted iteration has been archived under `iterations-control/`.

## Iteration limit

The maximum number of archived control iterations is **10**. Reaching the limit
is not success; stop with `iteration-limit-reached`.

## Stop conditions

Stop without claiming success when:

- a required input is absent;
- `schemabloc.sty` or the TeX toolchain is unavailable;
- the target or rendered image cannot be inspected;
- structured output is malformed;
- a worker reaches its runtime limit;
- the Reviewer asks for human review;
- an unrecoverable blocker is reported;
- the iteration limit is reached.