#!/usr/bin/env bash
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT="$ROOT_DIR/current"
LOGS="$ROOT_DIR/logs"
RESULT="$CURRENT/validation-result.json"
SCHEMA="$ROOT_DIR/schemas/validation-result.schema.json"
VALIDATOR="$ROOT_DIR/scripts/lib/validate_json_schema.py"
mkdir -p "$CURRENT" "$LOGS" "$ROOT_DIR/tmp"
export ROOT_DIR CURRENT LOGS RESULT
python3 <<'PY'
import json, os
from pathlib import Path
root = Path(os.environ['ROOT_DIR'])
current = Path(os.environ['CURRENT'])
logs = Path(os.environ['LOGS'])
result_path = Path(os.environ['RESULT'])
source = current / 'reconstruction.tex'
pdf = current / 'reconstruction.pdf'
png = current / 'reconstruction.png'
checks = []
def check(name, ok, message_ok, message_fail):
    checks.append({'name': name, 'status': 'passed' if ok else 'failed', 'message': message_ok if ok else message_fail})
    return ok
source_ok = check('source-exists', source.is_file() and source.stat().st_size > 0,
                  'The reconstruction source exists and is non-empty.', 'The reconstruction source is missing or empty.')
text = source.read_text(encoding='utf-8', errors='replace') if source_ok else ''
check('circuitikz-package', '\\usepackage' in text and 'circuitikz' in text,
      'The source loads CircuitTikZ.', 'The source does not visibly load CircuitTikZ.')
check('circuitikz-environment', '\\begin{circuitikz}' in text and '\\end{circuitikz}' in text,
      'The source contains a circuitikz environment.', 'The source lacks a complete circuitikz environment.')
check('target-not-embedded', 'reference/target.png' not in text and 'target.png' not in text,
      'The source does not reference the target raster.', 'The source appears to reference the target raster.')
pdf_ok = check('pdf-exists', pdf.is_file() and pdf.stat().st_size > 0,
               'The rendered PDF exists and is non-empty.', 'The rendered PDF is missing or empty.')
png_ok = check('png-exists', png.is_file() and png.stat().st_size > 0,
               'The rendered PNG exists and is non-empty.', 'The rendered PNG is missing or empty.')
render_error = logs / 'render.stderr.log'
rendering_status = 'passed' if pdf_ok and png_ok else ('failed' if render_error.exists() else 'not-run')
failed = [c['name'] for c in checks if c['status'] == 'failed']
result = {
    'status': 'failed' if failed else 'passed',
    'renderingStatus': rendering_status,
    'sourceArtifact': 'current/reconstruction.tex',
    'renderedArtifacts': [p for p, ok in [('current/reconstruction.pdf', pdf_ok), ('current/reconstruction.png', png_ok)] if ok],
    'checks': checks,
    'failureSummary': ('Failed checks: ' + ', '.join(failed)) if failed else None,
}
tmp = result_path.with_suffix('.json.tmp')
tmp.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
tmp.replace(result_path)
PY
python3 "$VALIDATOR" "$RESULT" "$SCHEMA" || exit 2
status="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status"])' "$RESULT")"
if [[ "$status" == "passed" ]]; then
  printf 'Deterministic validation passed.\n'
  exit 0
fi
printf 'Deterministic validation failed; see current/validation-result.json.\n' >&2
exit 1
