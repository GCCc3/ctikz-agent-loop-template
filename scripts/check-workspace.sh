#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0
require_file() {
  if [[ ! -s "$ROOT_DIR/$1" ]]; then
    printf 'MISSING OR EMPTY: %s\n' "$1" >&2
    failures=$((failures + 1))
  fi
}
require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'MISSING COMMAND: %s\n' "$1" >&2
    failures=$((failures + 1))
  fi
}
for file in \
  .omp/agents/diagram-generator.md \
  .omp/agents/diagram-reviewer.md \
  .omp/agents/efficiency.md \
  workflow/efficiency-analysis.md \
  scripts/render-efficiency-report.py \
  schemas/efficiency-report.schema.json \
  workflow/objective.md \
  workflow/coordinator.md \
  workflow/completion-criteria.md \
  workflow/generator-instructions.md \
  workflow/reviewer-instructions.md \
  workflow/current-human-feedback.md \
  reference/domain-rules.md \
  reference/target.png \
  current/reconstruction.tex \
  schemas/generation-result.schema.json \
  schemas/validation-result.schema.json \
  schemas/review-result.schema.json \
  schemas/iteration-manifest.schema.json; do
  require_file "$file"
done
require_command omp
require_command python3
if command -v latexmk >/dev/null 2>&1 || command -v lualatex >/dev/null 2>&1 || command -v pdflatex >/dev/null 2>&1; then
  :
else
  printf 'MISSING COMMAND: install latexmk, lualatex, or pdflatex\n' >&2
  failures=$((failures + 1))
fi
if command -v pdftoppm >/dev/null 2>&1 || command -v magick >/dev/null 2>&1; then
  :
else
  printf 'MISSING COMMAND: install pdftoppm or magick\n' >&2
  failures=$((failures + 1))
fi
for schema in "$ROOT_DIR"/schemas/*.json; do
  python3 -m json.tool "$schema" >/dev/null || failures=$((failures + 1))
done
if [[ ! -w "$ROOT_DIR/current" ]]; then
  printf 'NOT WRITABLE: current/\n' >&2
  failures=$((failures + 1))
fi
if (( failures > 0 )); then
  printf 'Workspace check failed with %d issue(s).\n' "$failures" >&2
  exit 1
fi
printf 'Workspace check passed.\n'
