#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/profile.sh
source "$ROOT_DIR/scripts/lib/profile.sh"

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
  .omp/agents/control-generator.md \
  .omp/agents/control-reviewer.md \
  .omp/mcp.json \
  .omp/skills/schemabloc-diagram/SKILL.md \
  scripts/control/init-current.sh \
  scripts/control/render.sh \
  scripts/control/validate.sh \
  scripts/control/archive-iteration.sh \
  scripts/control/next-iteration-number.sh \
  scripts/control/check-workspace.sh \
  schemas/schemabloc-snippets.schema.json \
  schemas/schemabloc-lint.schema.json \
  workflow/control/objective.md \
  workflow/control/completion-criteria.md \
  workflow/control/coordinator.md \
  workflow/control/generator-instructions.md \
  workflow/control/reviewer-instructions.md \
  workflow/control/domain-rules.md \
  workflow/control/current-human-feedback.md \
  reference/control_diagram.png \
  input/control-initial.tex \
  current-control/reconstruction.tex; do
  require_file "$file"
done

require_command omp
require_command python3
require_command kpsewhich
if command -v kpsewhich >/dev/null 2>&1; then
  if ! kpsewhich schemabloc.sty >/dev/null 2>&1; then
    printf 'MISSING TEX PACKAGE: schemabloc.sty\n' >&2
    failures=$((failures + 1))
  fi
fi
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

if (( failures > 0 )); then
  printf 'Control workspace check failed with %d issue(s).\n' "$failures" >&2
  exit 1
fi
printf 'Control workspace check passed.\n'
