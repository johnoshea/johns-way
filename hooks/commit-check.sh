#!/usr/bin/env bash
# PreToolUse hook on Bash: runs check.sh before any git commit and blocks the
# commit when the check fails. Exit code 2 blocks the tool call and shows
# stderr to the model.
#
# Skipping hooks is blocked outright. When the repository's own pre-commit
# hook is ours, git runs the same check, so this hook steps aside rather than
# run it twice.
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cwd" ] || cwd=$PWD

# "git commit" at the start of the command or after a separator, allowing
# git options such as -C <path> before the subcommand.
git_commit='(^|[;&|][[:space:]]*)git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)'
printf '%s' "$command" | grep -qE "$git_commit" || exit 0

if printf '%s' "$command" | grep -qE -- '(^|[[:space:]])(--no-verify|-[a-zA-Z]*n[a-zA-Z]*)([[:space:]]|$)'; then
    echo "Blocked: git commit with --no-verify. Hooks are never skipped. Fix what the check reports instead." >&2
    exit 2
fi

pre_commit=$(git -C "$cwd" rev-parse --git-path hooks/pre-commit 2>/dev/null || true)
if [ -n "$pre_commit" ] && [ -f "$pre_commit" ] && grep -q johns-way "$pre_commit"; then
    exit 0
fi

if ! output=$("$script_dir/check.sh" "$cwd" 2>&1); then
    printf 'Commit blocked: the check failed.\n%s\n' "$output" >&2
    exit 2
fi
