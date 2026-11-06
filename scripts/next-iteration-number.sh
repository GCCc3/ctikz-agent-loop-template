#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS="$ROOT_DIR/iterations"
mkdir -p "$ITERATIONS"
max=0
shopt -s nullglob
for path in "$ITERATIONS"/iteration-[0-9][0-9][0-9]; do
  name="$(basename "$path")"
  number="${name#iteration-}"
  value=$((10#$number))
  if (( value > max )); then max=$value; fi
done
printf '%d\n' "$((max + 1))"
