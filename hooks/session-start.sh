#!/usr/bin/env bash
# SessionStart hook: injects the routing skill and the session status.
# Reads the hook input JSON on stdin and writes the hook output JSON on stdout.
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)

cwd=$(jq -r '.cwd // empty' 2>/dev/null || true)
[ -n "$cwd" ] || cwd=$PWD

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
