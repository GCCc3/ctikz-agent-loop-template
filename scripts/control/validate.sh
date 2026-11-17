#!/usr/bin/env bash
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/profile.sh
source "$ROOT_DIR/scripts/lib/profile.sh"

CURRENT="$ROOT_DIR/$CURRENT_DIR"
LOGS="$ROOT_DIR/logs"
RESULT="$CURRENT/validation-result.json"
SCHEMA="$ROOT_DIR/schemas/validation-result.schema.json"
LINT_RESULT="$ROOT_DIR/tmp/control/lint-result.json"
DSKT_HOST="${DSKT_HOST:-127.0.0.1}"
DSKT_PORT="${DSKT_PORT:-8087}"
BASE_URL="http://$DSKT_HOST:$DSKT_PORT"
mkdir -p "$CURRENT" "$LOGS" "$ROOT_DIR/tmp/control"

SOURCE="$ROOT_DIR/$SOURCE_FILE"
PDF="$ROOT_DIR/$PDF_FILE"
PNG="$ROOT_DIR/$PNG_FILE"

if [[ ! -s "$SOURCE" ]]; then
  LINT_PAYLOAD='{"success":false,"error":{"code":"source_not_found","message":"source missing"}}'
else
  LINT_PAYLOAD="$(curl -sS --max-time 10 -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"path\":\"$SOURCE_FILE\",\"required_labels\":[]}" \
    "$BASE_URL/schemabloc/lint" 2>/dev/null || true)"
fi
if [[ -z "${LINT_PAYLOAD:-}" ]]; then
  LINT_PAYLOAD='{"success":false,"error":{"code":"lint_unavailable","message":"schemabloc lint service unavailable"}}'
fi
printf '%s\n' "$LINT_PAYLOAD" > "$LINT_RESULT"

export ROOT_DIR CURRENT LOGS RESULT SOURCE PDF PNG LINT_RESULT SOURCE_FILE
python3 <<'PY'
import json, os
from pathlib import Path

root = Path(os.environ['ROOT_DIR'])
result_path = Path(os.environ['RESULT'])
source = Path(os.environ['SOURCE'])
pdf = Path(os.environ['PDF'])
png = Path(os.environ['PNG'])
lint_path = Path(os.environ['LINT_RESULT'])
source_rel = os.environ['SOURCE_FILE']

checks = []
def add(name, ok, message_ok, message_fail):
    checks.append({
        'name': name,
        'status': 'passed' if ok else 'failed',
        'message': message_ok if ok else message_fail,
    })
    return ok

source_ok = add('source-exists', source.is_file() and source.stat().st_size > 0,
                'The reconstruction source exists and is non-empty.',
                'The reconstruction source is missing or empty.')

lint = None
try:
    lint = json.loads(lint_path.read_text(encoding='utf-8'))
except Exception:
    lint = None

lint_ok = False
lint_message = 'schemabloc lint result is unavailable.'
if isinstance(lint, dict) and lint.get('success') is True:
    summary = lint.get('result', {}).get('summary', {})
    failed = int(summary.get('failed', 0))
    warning = int(summary.get('warning', 0))
    passed = int(summary.get('passed', 0))
    lint_ok = failed == 0
    lint_message = f'schemabloc lint: passed={passed}, warning={warning}, failed={failed}'
elif isinstance(lint, dict):
    lint_message = 'schemabloc lint failed to run: ' + str(lint.get('error', {}).get('message', 'unknown error'))
add('schemabloc-lint', lint_ok, lint_message, lint_message)

pdf_ok = add('pdf-exists', pdf.is_file() and pdf.stat().st_size > 0,
             'The rendered PDF exists and is non-empty.',
             'The rendered PDF is missing or empty.')
png_ok = add('png-exists', png.is_file() and png.stat().st_size > 0,
             'The rendered PNG exists and is non-empty.',
             'The rendered PNG is missing or empty.')

failed = [c['name'] for c in checks if c['status'] == 'failed']
rendering_ok = pdf_ok and png_ok
result = {
    'status': 'failed' if failed else 'passed',
    'renderingStatus': 'passed' if rendering_ok else ('failed' if pdf.exists() or png.exists() else 'not-run'),
    'sourceArtifact': source_rel,
    'renderedArtifacts': [p for p, ok in [(os.environ['PDF_FILE'] if 'PDF_FILE' in os.environ else 'current-control/reconstruction.pdf', pdf_ok), (os.environ['PNG_FILE'] if 'PNG_FILE' in os.environ else 'current-control/reconstruction.png', png_ok)] if ok],
    'checks': checks,
    'failureSummary': ('Failed checks: ' + ', '.join(failed)) if failed else None,
}
tmp = result_path.with_suffix('.json.tmp')
tmp.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
tmp.replace(result_path)
PY

python3 "$ROOT_DIR/scripts/lib/validate_json_schema.py" "$RESULT" "$SCHEMA" || exit 2
status="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status"])' "$RESULT")"
if [[ "$status" == "passed" ]]; then
  printf 'Control validation passed.\n'
  exit 0
fi
printf 'Control validation failed; see %s.\n' "$RESULT" >&2
exit 1
