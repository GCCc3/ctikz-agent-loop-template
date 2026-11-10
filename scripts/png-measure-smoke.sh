#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${PDMT_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PDMT_PORT="${PDMT_PORT:-8087}"
PDMT_HOST="${PDMT_HOST:-127.0.0.1}"
PDMT_OUTPUT_ROOT="${PDMT_OUTPUT_ROOT:-$REPO_ROOT/tmp/png-measure}"
BASE_URL="http://$PDMT_HOST:$PDMT_PORT"
TARGET="$REPO_ROOT/reference/target.png"
TARGET_ABS="$(realpath "$TARGET")"

python_check() {
  local label="$1"
  python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success") is True, d; print("'"$label"': " + str(d.get("result",{}).get("tool_version", d.get("tool_version"))))'
}

request_post() {
  local path="$1"
  local payload="$2"
  curl -sS -X POST -H 'Content-Type: application/json' \
    -H "X-PDMT-Request-Id: smoke-$RANDOM-$RANDOM" \
    -H "X-PDMT-Client-Id: smoke-client" \
    -H "X-PDMT-Client-Role: reviewer" \
    -d "$payload" "$BASE_URL$path"
}

echo "health"
curl -sS "$BASE_URL/png/health" | python_check "health"

echo "inspect_image"
request_post /png/inspect_image "{
  \"image_path\": \"reference/target.png\",
  \"image_abs_path\": \"$TARGET_ABS\",
  \"output_root\": \"$PDMT_OUTPUT_ROOT\"
}" | python_check "inspect_image"

echo "make_ink_mask"
request_post /png/make_ink_mask "{
  \"image_path\": \"reference/target.png\",
  \"image_abs_path\": \"$TARGET_ABS\",
  \"output_root\": \"$PDMT_OUTPUT_ROOT\"
}" | python_check "make_ink_mask"

echo "measure_bounds"
request_post /png/measure_bounds "{
  \"image_path\": \"reference/target.png\",
  \"image_abs_path\": \"$TARGET_ABS\",
  \"output_root\": \"$PDMT_OUTPUT_ROOT\"
}" | python_check "measure_bounds"

echo "measure_regions"
request_post /png/measure_regions "{
  \"image_path\": \"reference/target.png\",
  \"image_abs_path\": \"$TARGET_ABS\",
  \"output_root\": \"$PDMT_OUTPUT_ROOT\",
  \"regions\": {\"frame\": [0.1, 0.1, 0.9, 0.9]},
  \"region_units\": \"normalized_image\"
}" | python_check "measure_regions"

echo "normalize_geometry"
request_post /png/normalize_geometry "{
  \"image_path\": \"reference/target.png\",
  \"image_abs_path\": \"$TARGET_ABS\",
  \"output_root\": \"$PDMT_OUTPUT_ROOT\",
  \"geometry\": {\"type\": \"point\", \"coordinates\": [349, 126]},
  \"from\": \"image_pixels\",
  \"to\": \"normalized_ink\"
}" | python_check "normalize_geometry"

echo "create_baseline"
request_post /png/create_baseline "{
  \"image_path\": \"reference/target.png\",
  \"image_abs_path\": \"$TARGET_ABS\",
  \"output_root\": \"$PDMT_OUTPUT_ROOT\",
  \"output_path\": \"target.baseline.json\",
  \"regions\": {\"frame\": [0.1, 0.1, 0.9, 0.9]},
  \"region_units\": \"normalized_image\"
}" | python_check "create_baseline"

echo "trace"
curl -sS "$BASE_URL/png/trace?limit=5" | python_check "trace"

echo "invalid_json_status"
STATUS="$(curl -sS -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{bad json' "$BASE_URL/png/measure_bounds")"
if [[ "$STATUS" != "400" ]]; then
  echo "expected 400 for malformed JSON, got $STATUS" >&2
  exit 1
fi

echo "path_escape_status"
STATUS="$(curl -sS -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' \
  -d '{"image_path":"../outside.png","image_abs_path":"/tmp/outside.png","output_root":"'"$PDMT_OUTPUT_ROOT"'"}' \
  "$BASE_URL/png/inspect_image")"
if [[ "$STATUS" != "400" ]]; then
  echo "expected 400 for path escape, got $STATUS" >&2
  exit 1
fi

echo "smoke ok"
