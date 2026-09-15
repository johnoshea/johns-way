#!/usr/bin/env bash
# Prints the last assistant message from the Stop hook input on stdin.
# Codex supplies it as last_assistant_message. Claude Code gives a transcript
# path instead, and the last 400 lines of any transcript hold the final
# message. Malformed lines are skipped rather than fatal. Always exits 0.
set -uo pipefail
input=$(cat)
if printf '%s' "$input" | jq -e 'has("last_assistant_message")' >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '.last_assistant_message // ""'
    exit 0
fi
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""' 2>/dev/null) || exit 0
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
tail -n 400 "$transcript" 2>/dev/null \
  | jq -R 'fromjson? // empty' 2>/dev/null \
  | jq -s -r '[.[]
      | select(.type == "assistant")
      | .message.content[]?
      | select(.type == "text")
      | .text] | last // ""' 2>/dev/null
exit 0
