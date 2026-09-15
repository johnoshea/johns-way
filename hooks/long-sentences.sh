#!/usr/bin/env bash
# Prints every sentence in the text on stdin that holds more than one idea:
# over 25 words, or joined to another by a semicolon. Fenced code blocks,
# inline code, and table rows are left out. Wrapped lines are joined within
# a paragraph before splitting, and a list item starts a paragraph of its
# own. Always exits 0; the caller decides what the output means.
set -euo pipefail
awk '
    /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }
    fenced { next }
    /^[[:space:]]*\|/ { next }
    /^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]/ { print "" }
    { print }
' \
| sed -E "s/\`[^\`]*\`//g" \
| awk 'BEGIN { RS = "" } { gsub(/\n/, " "); print }' \
| sed -E 's/([.!?])[[:space:]]+/\1\
/g' \
| awk 'NF > 25 || /;/' || true
