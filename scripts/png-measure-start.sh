#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${DSKT_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PHARO="${PHARO:-pharo}"
DSKT_IMAGE="${DSKT_IMAGE:-$REPO_ROOT/tmp/dskt/DsktService.image}"
DSKT_PORT="${DSKT_PORT:-8087}"
DSKT_HOST="${DSKT_HOST:-127.0.0.1}"
PNG_OUTPUT_ROOT="${PNG_OUTPUT_ROOT:-$REPO_ROOT/tmp/png-measure}"
DSKT_TRACE_LOG="${DSKT_TRACE_LOG:-$REPO_ROOT/tmp/dskt/tool-trace.jsonl}"
PNG_MAX_PIXELS="${PNG_MAX_PIXELS:-50000000}"
DSKT_TRACE_ENTRIES="${DSKT_TRACE_ENTRIES:-1000}"
DSKT_TRACE_MAX_BYTES="${DSKT_TRACE_MAX_BYTES:-5000000}"
DSKT_DEBUG="${DSKT_DEBUG:-0}"
DSKT_AUTOSTART=1

if [[ ! -f "$DSKT_IMAGE" ]]; then
  echo "DSKT_IMAGE does not exist: $DSKT_IMAGE" >&2
  echo "Run scripts/png-measure-install.sh first." >&2
  exit 2
fi

export DSKT_AUTOSTART DSKT_PORT DSKT_HOST PNG_OUTPUT_ROOT DSKT_TRACE_LOG
export PNG_MAX_PIXELS DSKT_TRACE_ENTRIES DSKT_TRACE_MAX_BYTES DSKT_DEBUG DSKT_REPO_ROOT
exec "$PHARO" --headless "$DSKT_IMAGE" eval "(Smalltalk at: #DsktServer) startUp: true. (Delay forSeconds: 31536000) wait"
