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
CHECK=0
if [[ "${1:-}" == "--check" ]]; then CHECK=1; fi

if [[ -z "${DSKT_CIRCUITIKZ_STY:-}" ]] && command -v kpsewhich >/dev/null 2>&1; then
  DSKT_CIRCUITIKZ_STY="$(kpsewhich circuitikz.sty 2>/dev/null || true)"
fi
if [[ -z "${DSKT_SCHEMABLOC_STY:-}" ]] && command -v kpsewhich >/dev/null 2>&1; then
  DSKT_SCHEMABLOC_STY="$(kpsewhich schemabloc.sty 2>/dev/null || true)"
fi

if [[ ! -f "$DSKT_IMAGE" ]]; then
  if [[ -z "$DSKT_BASE_IMAGE" || ! -f "$DSKT_BASE_IMAGE" ]]; then
    echo "DSKT_IMAGE does not exist and DSKT_BASE_IMAGE is not set to a base image." >&2
    echo "Set DSKT_BASE_IMAGE to a Pharo image to copy, or provide DSKT_IMAGE." >&2
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
if [[ -n "${DSKT_CIRCUITIKZ_STY:-}" ]]; then export DSKT_CIRCUITIKZ_STY; fi
if [[ -n "${DSKT_SCHEMABLOC_STY:-}" ]]; then export DSKT_SCHEMABLOC_STY; fi

SNAPSHOT="true"
if [[ "$CHECK" -eq 1 ]]; then SNAPSHOT="false"; fi

"$PHARO" --headless "$DSKT_IMAGE" eval "
| providers catalog |
Metacello new baseline: 'Dskt';
  repository: 'tonel://$REPO_ROOT/tools/dskt/pharo/src';
  load: 'Core'.
Metacello new baseline: 'PngDiagramMeasure';
  repository: 'tonel://$REPO_ROOT/tools/png-measure/pharo/src';
  load: 'Core'.
Metacello new baseline: 'CtikzTools';
  repository: 'tonel://$REPO_ROOT/tools/circuitikz-tools/pharo/src';
  load: 'Core'.
Metacello new baseline: 'Schemabloc';
  repository: 'tonel://$REPO_ROOT/tools/schemabloc-tools/pharo/src';
  load: 'Core'.
((Smalltalk at: #DsktRouteRegistry) current providerNamed: 'schemabloc')
  ifNil: [ (Smalltalk at: #SchemablocRouteProvider) initialize ].
providers := ((Smalltalk at: #DsktRouteRegistry) current providers collect: [ :each | each name ]) asArray.
(providers includes: 'png') ifFalse: [ Error signal: 'png provider is not registered' ].
(providers includes: 'ctikz') ifFalse: [ Error signal: 'ctikz provider is not registered' ].
(providers includes: 'schemabloc') ifFalse: [ Error signal: 'schemabloc provider is not registered' ].
catalog := (Smalltalk at: #CtikzSnippetCatalog) default.
catalog validationWarnings ifNotEmpty: [ Error signal: 'catalog validation failed: ' , catalog validationWarnings printString ].
catalog := (Smalltalk at: #SchemablocSnippetCatalog) default.
catalog validationWarnings ifNotEmpty: [ Error signal: 'schemabloc catalog validation failed: ' , catalog validationWarnings printString ].
(Smalltalk at: #DsktServer) installStartup.
Transcript show: 'Dskt providers: '; show: providers printString; cr.
Smalltalk snapshot: $SNAPSHOT andQuit: true
"
