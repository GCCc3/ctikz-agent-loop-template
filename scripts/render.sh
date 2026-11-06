#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT="$ROOT_DIR/current"
LOGS="$ROOT_DIR/logs"
SOURCE="$CURRENT/reconstruction.tex"
PDF="$CURRENT/reconstruction.pdf"
PNG="$CURRENT/reconstruction.png"
mkdir -p "$CURRENT" "$LOGS"
: > "$LOGS/render.stdout.log"
: > "$LOGS/render.stderr.log"
rm -f "$PDF" "$PNG"
if [[ ! -s "$SOURCE" ]]; then
  printf 'Source is missing or empty: %s\n' "$SOURCE" | tee -a "$LOGS/render.stderr.log" >&2
  exit 1
fi
set +e
if command -v latexmk >/dev/null 2>&1; then
  latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
    -output-directory="$CURRENT" "$SOURCE" \
    >>"$LOGS/render.stdout.log" 2>>"$LOGS/render.stderr.log"
  compile_status=$?
elif command -v lualatex >/dev/null 2>&1; then
  lualatex -interaction=nonstopmode -halt-on-error -file-line-error \
    -output-directory="$CURRENT" "$SOURCE" \
    >>"$LOGS/render.stdout.log" 2>>"$LOGS/render.stderr.log"
  compile_status=$?
elif command -v pdflatex >/dev/null 2>&1; then
  pdflatex -interaction=nonstopmode -halt-on-error -file-line-error \
    -output-directory="$CURRENT" "$SOURCE" \
    >>"$LOGS/render.stdout.log" 2>>"$LOGS/render.stderr.log"
  compile_status=$?
else
  printf 'No supported LaTeX compiler found.\n' >>"$LOGS/render.stderr.log"
  compile_status=127
fi
set -e
if (( compile_status != 0 )) || [[ ! -s "$PDF" ]]; then
  printf 'LaTeX rendering failed. See logs/render.stderr.log.\n' >&2
  exit 1
fi
if command -v pdftoppm >/dev/null 2>&1; then
  pdftoppm -png -singlefile -r 180 "$PDF" "$CURRENT/reconstruction" \
    >>"$LOGS/render.stdout.log" 2>>"$LOGS/render.stderr.log"
elif command -v magick >/dev/null 2>&1; then
  magick -density 180 "${PDF}[0]" -background white -alpha remove "$PNG" \
    >>"$LOGS/render.stdout.log" 2>>"$LOGS/render.stderr.log"
else
  printf 'No supported PDF-to-PNG converter found.\n' >>"$LOGS/render.stderr.log"
  exit 1
fi
if [[ ! -s "$PNG" ]]; then
  printf 'PNG rendering failed. See logs/render.stderr.log.\n' >&2
  exit 1
fi
printf 'Rendered %s and %s\n' "$PDF" "$PNG"
