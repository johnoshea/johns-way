#!/usr/bin/env bash
# SessionStart hook: injects the routing skill and the session status, and
# records the session's start time for check-in.sh.
# Reads the hook input JSON on stdin and writes the hook output JSON on stdout.
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cwd" ] || cwd=$PWD

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
if [ -n "$session_id" ]; then
    sessions=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/johns-way}/sessions
    mkdir -p "$sessions"
    date +%s > "$sessions/$session_id.start"
    rm -f "$sessions/$session_id.notified"
    find "$sessions" -type f -mtime +7 -delete
fi

# The skill text without its YAML frontmatter.
routing=$(awk 'NR == 1 && /^---$/ {skip = 1; next} skip && /^---$/ {skip = 0; next} !skip' \
    "$script_dir/../skills/routing/SKILL.md")

status=$("$script_dir/progress-status.sh" "$cwd")

context=$routing
if [ -n "$status" ]; then
    context="$context

## Session status

$status"
fi

jq -n --arg context "$context" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $context}}'
