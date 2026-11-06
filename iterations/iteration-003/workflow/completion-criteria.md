# Completion criteria

The workflow succeeds only when all conditions below hold:

1. `current/reconstruction.tex` exists and is non-empty.
2. CircuitTikZ is the primary diagram implementation mechanism.
3. The document compiles successfully.
4. `current/reconstruction.pdf` and `current/reconstruction.png` exist and are
   non-empty.
5. Deterministic validation reports `passed`.
6. The Reviewer returns `accept`.
7. The review contains no critical or major findings.
8. The latest human feedback, if any, has been addressed.
9. The accepted iteration has been archived.

## Iteration limit

The maximum number of archived iterations is **10**.

Reaching the limit is not success. Stop with status
`iteration-limit-reached`, summarize the best available result, and identify
remaining findings.

## Stop conditions

Stop without claiming success when:

- a required input is absent;
- the target or rendered image cannot be inspected;
- rendering infrastructure is unavailable;
- structured output is malformed;
- a worker reaches its runtime limit;
- the Reviewer asks for human review;
- an unrecoverable blocker is reported;
- the iteration limit is reached.
