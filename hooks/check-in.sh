#!/usr/bin/env bash
# PostToolUse hook: once per session, after the session has run for
# JOHNS_WAY_CHECKIN_MINUTES (60 by default), tells the model to check in
# about any medium task in progress. session-start.sh records the start time.
set -euo pipefail

session_id=$(jq -r '.session_id // empty')
[ -n "$session_id" ] || exit 0

sessions=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/johns-way}/sessions
start_file=$sessions/$session_id.start
notified_file=$sessions/$session_id.notified
[ -f "$start_file" ] || exit 0
[ -f "$notified_file" ] && exit 0

limit=${JOHNS_WAY_CHECKIN_MINUTES:-60}
elapsed=$(( ($(date +%s) - $(cat "$start_file")) / 60 ))
[ "$elapsed" -ge "$limit" ] || exit 0

touch "$notified_file"
jq -n --arg minutes "$elapsed" '{hookSpecificOutput: {hookEventName: "PostToolUse",
    additionalContext: ("Session check-in: this session has run for " + $minutes
        + " minutes. If a medium task is in progress, stop and ask with AskUserQuestion"
        + " whether to continue as medium or upgrade to full. Otherwise carry on.")}}'
