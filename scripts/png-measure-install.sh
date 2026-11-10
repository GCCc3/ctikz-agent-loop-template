#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${PDMT_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PHARO="${PHARO:-pharo}"
PDMT_IMAGE="${PDMT_IMAGE:-$REPO_ROOT/tmp/png-measure/PngMeasure.image}"
PDMT_BASE_IMAGE="${PDMT_BASE_IMAGE:-}"
PDMT_PORT="${PDMT_PORT:-8087}"
PDMT_HOST="${PDMT_HOST:-127.0.0.1}"
PDMT_OUTPUT_ROOT="${PDMT_OUTPUT_ROOT:-$REPO_ROOT/tmp/png-measure}"
PDMT_TRACE_LOG="${PDMT_TRACE_LOG:-$PDMT_OUTPUT_ROOT/tool-trace.jsonl}"
PDMT_REPO_ROOT="$REPO_ROOT"
PDMT_AUTOSTART=0

if [[ ! -f "$PDMT_IMAGE" ]]; then
  if [[ -z "$PDMT_BASE_IMAGE" || ! -f "$PDMT_BASE_IMAGE" ]]; then
    echo "PDMT_IMAGE does not exist and PDMT_BASE_IMAGE is not set to a base image." >&2
    echo "Set PDMT_BASE_IMAGE to a Pharo 13.1 image to copy, or provide PDMT_IMAGE." >&2
    exit 2
  fi
  mkdir -p "$(dirname "$PDMT_IMAGE")"
  cp "$PDMT_BASE_IMAGE" "$PDMT_IMAGE"
  base_changes="${PDMT_BASE_IMAGE%.image}.changes"
  image_changes="${PDMT_IMAGE%.image}.changes"
  if [[ -f "$base_changes" ]]; then cp "$base_changes" "$image_changes"; fi
fi

if pgrep -f "$PDMT_IMAGE" >/dev/null 2>&1; then
  echo "The image appears to be running. Stop the PDM service before reinstalling." >&2
  exit 1
fi

export PDMT_AUTOSTART PDMT_PORT PDMT_HOST PDMT_OUTPUT_ROOT PDMT_TRACE_LOG PDMT_REPO_ROOT
"$PHARO" --headless "$PDMT_IMAGE" eval "
Metacello new baseline: 'PngDiagramMeasure';
  repository: 'tonel://$REPO_ROOT/tools/png-measure/pharo/src';
  load: 'Core'.
PmdtServer installStartup.
Smalltalk snapshot: true andQuit: true
"
