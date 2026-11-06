#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 3 ]]; then
  printf 'usage: %s CANDIDATE.json TARGET.json SCHEMA.json\n' "$0" >&2
  exit 2
fi
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANDIDATE="$1"
TARGET="$2"
SCHEMA="$3"
for path in "$CANDIDATE" "$SCHEMA"; do
  if [[ ! -s "$path" ]]; then
    printf 'Missing or empty input: %s\n' "$path" >&2
    exit 1
  fi
done
python3 "$ROOT_DIR/scripts/lib/validate_json_schema.py" "$CANDIDATE" "$SCHEMA"
mkdir -p "$(dirname "$TARGET")"
TEMP="${TARGET}.tmp.$$"
trap 'rm -f "$TEMP"' EXIT
python3 -m json.tool "$CANDIDATE" > "$TEMP"
mv "$TEMP" "$TARGET"
trap - EXIT
printf 'Persisted validated result to %s\n' "$TARGET"
