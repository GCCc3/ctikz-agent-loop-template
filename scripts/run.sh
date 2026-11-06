#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT_DIR/scripts/init-current.sh"
"$ROOT_DIR/scripts/check-workspace.sh"
cd "$ROOT_DIR"
exec omp \
  @workflow/coordinator.md \
  @workflow/objective.md \
  "Execute the sequential CircuitTikZ generator-reviewer workflow exactly as specified."
