#!/usr/bin/env bash
# scripts/check-file-size.sh - enforce 500-line file cap per ~/.claude/rules/code-modularity-standards.md.
#
# Allow-list at .file-size-allow-list.
# Runs in CI (via .github/workflows/file-size-gate.yml) and locally.

set -euo pipefail

ALLOW_LIST="${ALLOW_LIST:-.file-size-allow-list}"
if [ ! -f "$ALLOW_LIST" ]; then
  echo "ERROR: $ALLOW_LIST is missing."
  echo "Create it with justified exceptions per code-modularity-standards.md."
  exit 1
fi

ALLOW_PATTERNS=$(mktemp)
OFFENDER_FILE=$(mktemp)
trap 'rm -f "$ALLOW_PATTERNS" "$OFFENDER_FILE"' EXIT

awk '
  {
    line = $0
    sub(/[[:space:]]+#.*/, "", line)
    sub(/^#.*$/, "", line)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
    if (line != "") {
      print line
      if (line !~ /^\.\//) {
        print "./" line
      }
    }
  }
' "$ALLOW_LIST" >"$ALLOW_PATTERNS"

find . -type f \
  \( -name '*.py' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \
     -o -name '*.rs' -o -name '*.go' -o -name '*.swift' \) \
  -not -path './.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/.venv/*' \
  -not -path '*/venv/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/build/*' \
  -not -path '*/dist/*' \
  -not -path '*/target/*' \
  -not -path '*/_generated/*' \
  -print0 |
  while IFS= read -r -d '' file; do
    # awk 'END{print NR}' counts lines including a final line without a trailing newline.
    # 'wc -l' counts newlines, undercounting by 1 when the last line is unterminated.
    count=$(awk 'END{print NR}' "$file")
    path_without_dot=${file#./}
    if [ "$count" -gt 500 ] &&
      ! grep -Fxq "$file" "$ALLOW_PATTERNS" &&
      ! grep -Fxq "$path_without_dot" "$ALLOW_PATTERNS"; then
      printf '%s (%s lines)\n' "$file" "$count"
    fi
  done >"$OFFENDER_FILE"

if [ -s "$OFFENDER_FILE" ]; then
  echo "::error::Files exceeding 500-line cap (per code-modularity-standards):"
  cat "$OFFENDER_FILE"
  echo ""
  echo "Fix: decompose along natural boundaries (SRP) OR add to $ALLOW_LIST with one-line justification."
  exit 1
fi

echo "All source files within 500-line cap."
