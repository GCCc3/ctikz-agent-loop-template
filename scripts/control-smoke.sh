#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DSKT_HOST="${DSKT_HOST:-127.0.0.1}"
DSKT_PORT="${DSKT_PORT:-8087}"
BASE_URL="http://$DSKT_HOST:$DSKT_PORT"

python_check() {
  local label="$1"
  python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success") is True, d; print("'"$label"': ok")'
}

echo "schemabloc_health"
curl -sS "$BASE_URL/schemabloc/health" | python_check "schemabloc_health"

echo "list_snippets"
curl -sS "$BASE_URL/schemabloc/snippets" | python_check "list_snippets"

echo "render_block"
curl -sS -X POST -H 'Content-Type: application/json' \
  -d '{"snippet_id":"block","parameters":{"name":"G","content":"$G(s)$","previous":"input","offset":"2.0"}}' \
  "$BASE_URL/schemabloc/render_snippet" | python_check "render_block"

echo "lint_seed"
curl -sS -X POST -H 'Content-Type: application/json' \
  -d '{"path":"input/control-initial.tex","required_labels":[]}' \
  "$BASE_URL/schemabloc/lint" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success") is True, d; print("lint_seed: ok", d["result"]["summary"])'

if command -v kpsewhich >/dev/null 2>&1 && kpsewhich schemabloc.sty >/dev/null 2>&1; then
  echo "schemabloc_installed"
  kpsewhich schemabloc.sty
else
  echo "schemabloc NOT installed; compile smoke skipped" >&2
fi

echo "control smoke ok"
