#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${PDMT_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SOURCE="${1:-$REPO_ROOT/tmp/png-measure/target.baseline.json}"
TARGET="${2:-$REPO_ROOT/reference/target.measurements.json}"
SCHEMA="$REPO_ROOT/schemas/png-measurement.schema.json"

if [[ ! -f "$SOURCE" ]]; then
  echo "Baseline source does not exist: $SOURCE" >&2
  exit 2
fi

python3 - "$SOURCE" "$SCHEMA" <<'PY'
import json, sys
from pathlib import Path

source = Path(sys.argv[1])
schema_path = Path(sys.argv[2])
document = json.loads(source.read_text())
required = {
    "schema_version", "tool_version", "image", "parameters", "mask",
    "bounds", "regions", "baseline_sha256", "warnings",
}
missing = required - set(document)
if missing:
    raise SystemExit(f"Baseline is missing required keys: {sorted(missing)}")
if document["schema_version"] != 1:
    raise SystemExit(f"Unsupported schema_version: {document['schema_version']}")
if len(document["baseline_sha256"]) != 64:
    raise SystemExit("baseline_sha256 must be 64 hex characters")
if not isinstance(document["image"], dict) or "sha256" not in document["image"]:
    raise SystemExit("Baseline image.sha256 is required")

try:
    import jsonschema
except ImportError:
    jsonschema = None
if jsonschema is not None:
    jsonschema.validate(document, json.loads(schema_path.read_text()))
PY

mkdir -p "$(dirname "$TARGET")"
cp "$SOURCE" "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"
echo "promoted $SOURCE -> $TARGET"
