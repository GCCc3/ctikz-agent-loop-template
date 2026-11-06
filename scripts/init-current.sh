#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/input/initial-reconstruction.tex"
TARGET="$ROOT_DIR/current/reconstruction.tex"
mkdir -p "$ROOT_DIR/current" "$ROOT_DIR/logs" "$ROOT_DIR/tmp" "$ROOT_DIR/iterations"
if [[ ! -e "$TARGET" ]]; then
  cp "$SOURCE" "$TARGET"
  printf 'Initialized %s\n' "$TARGET"
else
  printf 'Kept existing %s\n' "$TARGET"
fi
