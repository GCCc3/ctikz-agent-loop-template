#!/usr/bin/env bash
set -euo pipefail

PROFILE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -n "${WORKFLOW_PROFILE:-}" ]]; then
  PROFILE_NAME="$WORKFLOW_PROFILE"
else
  case "${0:-}" in
    *scripts/control/*) PROFILE_NAME="control" ;;
    *) PROFILE_NAME="circuit" ;;
  esac
fi
PROFILE_FILE="$PROFILE_ROOT/workflow/profiles/$PROFILE_NAME.env"

if [[ ! -f "$PROFILE_FILE" ]]; then
  printf 'Unknown workflow profile: %s\n' "$PROFILE_NAME" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
source "$PROFILE_FILE"
set +a

ROOT_DIR="$PROFILE_ROOT"
export ROOT_DIR PROFILE_ROOT PROFILE_NAME
export WORKFLOW_PROFILE TARGET_IMAGE CURRENT_DIR SOURCE_FILE PDF_FILE PNG_FILE
export ITERATIONS_DIR WORKFLOW_DIR GENERATOR_AGENT REVIEWER_AGENT
export PRIMARY_TEX_PACKAGE VALIDATION_MODE
