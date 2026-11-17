#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/profile.sh
source "$ROOT_DIR/scripts/lib/profile.sh"

"$ROOT_DIR/scripts/control/init-current.sh"
"$ROOT_DIR/scripts/control/check-workspace.sh"
cd "$ROOT_DIR"
exec omp \
  @workflow/control/coordinator.md \
  @workflow/control/objective.md \
  "Execute the sequential schemabloc control-diagram generator-reviewer workflow exactly as specified."
