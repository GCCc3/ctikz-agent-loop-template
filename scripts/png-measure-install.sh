#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${DSKT_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PHARO="${PHARO:-pharo}"
DSKT_IMAGE="${DSKT_IMAGE:-$REPO_ROOT/tmp/dskt/DsktService.image}"
DSKT_BASE_IMAGE="${DSKT_BASE_IMAGE:-}"
DSKT_PORT="${DSKT_PORT:-8087}"
DSKT_HOST="${DSKT_HOST:-127.0.0.1}"
PNG_OUTPUT_ROOT="${PNG_OUTPUT_ROOT:-$REPO_ROOT/tmp/png-measure}"
DSKT_TRACE_LOG="${DSKT_TRACE_LOG:-$REPO_ROOT/tmp/dskt/tool-trace.jsonl}"
DSKT_REPO_ROOT="$REPO_ROOT"
DSKT_AUTOSTART=0

if [[ ! -f "$DSKT_IMAGE" ]]; then
  if [[ -z "$DSKT_BASE_IMAGE" || ! -f "$DSKT_BASE_IMAGE" ]]; then
    echo "DSKT_IMAGE does not exist and DSKT_BASE_IMAGE is not set to a base image." >&2
    echo "Set DSKT_BASE_IMAGE to a Pharo 13.1 image to copy, or provide DSKT_IMAGE." >&2
    exit 2
  fi
  mkdir -p "$(dirname "$DSKT_IMAGE")"
  cp "$DSKT_BASE_IMAGE" "$DSKT_IMAGE"
  base_changes="${DSKT_BASE_IMAGE%.image}.changes"
  image_changes="${DSKT_IMAGE%.image}.changes"
  if [[ -f "$base_changes" ]]; then cp "$base_changes" "$image_changes"; fi
fi

if pgrep -f "$DSKT_IMAGE" >/dev/null 2>&1; then
  echo "The image appears to be running. Stop the Dskt service before reinstalling." >&2
  exit 1
fi

export DSKT_AUTOSTART DSKT_PORT DSKT_HOST PNG_OUTPUT_ROOT DSKT_TRACE_LOG DSKT_REPO_ROOT
"$PHARO" --headless "$DSKT_IMAGE" eval "
Metacello new baseline: 'PngDiagramMeasure';
  repository: 'tonel://$REPO_ROOT/tools/png-measure/pharo/src';
  load: 'Core'.
(Smalltalk at: #DsktServer) installStartup.
Smalltalk snapshot: true andQuit: true
"
