#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${DSKT_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DSKT_PORT="${DSKT_PORT:-8087}"
DSKT_HOST="${DSKT_HOST:-127.0.0.1}"
BASE_URL="http://$DSKT_HOST:$DSKT_PORT"

python_check() {
  local label="$1"
  python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success") is True, d; print("'"$label"': ok")'
}

request_post() {
  local path="$1"
  local payload="$2"
  curl -sS -X POST -H 'Content-Type: application/json' \
    -H "X-DSKT-Request-Id: smoke-$RANDOM-$RANDOM" \
    -H "X-DSKT-Client-Id: smoke-client" \
    -H "X-DSKT-Client-Role: reviewer" \
    -d "$payload" "$BASE_URL$path"
}

echo "health"
curl -sS "$BASE_URL/health" | python_check "health"

echo "ctikz_health"
curl -sS "$BASE_URL/ctikz/health" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success") is True, d; r=d["result"]; assert r["catalog_status"] == "valid", r; assert r["snippet_count"] == 12, r; print("ctikz_health: ok")'

echo "list_snippets"
curl -sS "$BASE_URL/ctikz/snippets?component=L" | python_check "list_snippets"

echo "get_snippet"
curl -sS "$BASE_URL/ctikz/snippets/component/L" | python_check "get_snippet"

echo "render_snippet"
request_post /ctikz/render_snippet \
  '{"snippet_id":"component/L","parameters":{"start":"c1","end":"c2"}}' \
  | python_check "render_snippet"

echo "lookup_component"
request_post /ctikz/components '{"component":"L"}' | python_check "lookup_component"

echo "lint_source"
request_post /ctikz/lint '{"path":"current/reconstruction.tex"}' \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success") is True, d; r=d["result"]; assert r["summary"]["failed"] == 0, d; assert r["source_path"] == "current/reconstruction.tex", r; print("lint_source: ok")'

echo "trace"
curl -sS "$BASE_URL/trace?limit=20" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success") is True, d; entries=d["result"]["entries"]; assert any(e.get("tool_family") in ("catalog", "lint") for e in entries), entries; print("trace: ok")'

echo "path_escape_status"
STATUS="$(curl -sS -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' \
  -d '{"path":"../outside.tex"}' "$BASE_URL/ctikz/lint")"
if [[ "$STATUS" != "400" ]]; then
  echo "expected 400 for path escape, got $STATUS" >&2
  exit 1
fi

echo "smoke ok"
