#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/profile.sh
source "$ROOT_DIR/scripts/lib/profile.sh"

SOURCE="$ROOT_DIR/input/control-initial.tex"
TARGET="$ROOT_DIR/$SOURCE_FILE"

mkdir -p "$ROOT_DIR/$CURRENT_DIR" "$ROOT_DIR/logs" "$ROOT_DIR/tmp/control" "$ROOT_DIR/$ITERATIONS_DIR"
if [[ ! -f "$SOURCE" ]]; then
  printf 'Missing initial reconstruction: %s\n' "$SOURCE" >&2
  exit 1
fi
if [[ ! -e "$TARGET" ]]; then
  cp "$SOURCE" "$TARGET"
  printf 'Initialized %s\n' "$TARGET"
else
  printf 'Kept existing %s\n' "$TARGET"
fi
