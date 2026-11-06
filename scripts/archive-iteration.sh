#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT="$ROOT_DIR/current"
ITERATIONS="$ROOT_DIR/iterations"
NUMBER="$($ROOT_DIR/scripts/next-iteration-number.sh)"
PADDED="$(printf '%03d' "$NUMBER")"
FINAL="$ITERATIONS/iteration-$PADDED"
PARTIAL="$ROOT_DIR/tmp/iteration-$PADDED.partial"
if [[ -e "$FINAL" ]]; then
  printf 'Refusing to overwrite %s\n' "$FINAL" >&2
  exit 1
fi
rm -rf "$PARTIAL"
mkdir -p "$PARTIAL/source" "$PARTIAL/rendered" "$PARTIAL/results" "$PARTIAL/workflow" "$PARTIAL/logs"
copy_if_present() {
  local source="$1" target="$2"
  if [[ -f "$source" ]]; then cp "$source" "$target"; fi
}
copy_if_present "$CURRENT/reconstruction.tex" "$PARTIAL/source/reconstruction.tex"
copy_if_present "$CURRENT/reconstruction.pdf" "$PARTIAL/rendered/reconstruction.pdf"
copy_if_present "$CURRENT/reconstruction.png" "$PARTIAL/rendered/reconstruction.png"
copy_if_present "$CURRENT/generation-result.json" "$PARTIAL/results/generation-result.json"
copy_if_present "$CURRENT/validation-result.json" "$PARTIAL/results/validation-result.json"
copy_if_present "$CURRENT/review-result.json" "$PARTIAL/results/review-result.json"
for name in objective.md completion-criteria.md generator-instructions.md reviewer-instructions.md current-human-feedback.md; do
  copy_if_present "$ROOT_DIR/workflow/$name" "$PARTIAL/workflow/$name"
done
if [[ -d "$ROOT_DIR/logs" ]]; then
  find "$ROOT_DIR/logs" -maxdepth 1 -type f -exec cp {} "$PARTIAL/logs/" \;
fi
# Subagent transcripts staged by the coordinator, kept split by role.
if [[ -d "$ROOT_DIR/tmp/transcripts" ]]; then
  mkdir -p "$PARTIAL/transcripts"
  cp -R "$ROOT_DIR/tmp/transcripts/." "$PARTIAL/transcripts/"
fi
export PARTIAL NUMBER
python3 <<'PY'
import json, os
from datetime import datetime, timezone
from pathlib import Path
partial = Path(os.environ['PARTIAL'])
number = int(os.environ['NUMBER'])
review_path = partial / 'results' / 'review-result.json'
generation_path = partial / 'results' / 'generation-result.json'
status = 'unknown'
reason = None
if review_path.exists():
    review = json.loads(review_path.read_text(encoding='utf-8'))
    status = review.get('decision', 'unknown')
    reason = review.get('summary')
elif generation_path.exists():
    generation = json.loads(generation_path.read_text(encoding='utf-8'))
    gen_status = generation.get('status', 'unknown')
    status = 'failed' if gen_status == 'failed' else ('blocked' if gen_status == 'blocked' else 'unknown')
    reason = generation.get('blocker') or generation.get('summary')
files = sorted(str(p.relative_to(partial)) for p in partial.rglob('*') if p.is_file())
manifest = {
    'iteration': number,
    'archivedAt': datetime.now(timezone.utc).isoformat(),
    'status': status,
    'files': files,
    'terminationReason': reason,
}
(partial / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
PY
python3 "$ROOT_DIR/scripts/lib/validate_json_schema.py" \
  "$PARTIAL/manifest.json" "$ROOT_DIR/schemas/iteration-manifest.schema.json"
mkdir -p "$ITERATIONS"
mv "$PARTIAL" "$FINAL"
# The staged transcripts now live in the archive; clear them so the next
# iteration cannot inherit a stale role directory.
if [[ -d "$ROOT_DIR/tmp/transcripts" ]]; then
  rm -rf "$ROOT_DIR/tmp/transcripts"
fi
printf 'Archived iteration %s at %s\n' "$NUMBER" "$FINAL"
