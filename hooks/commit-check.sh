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
# git options such as -C <path> before the subcommand. The commit segment
# runs from there to the next separator; only it is inspected further.
git_commit='(^|[;&|][[:space:]]*)git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)'
segment=$(printf '%s' "$command" | grep -oE "${git_commit}[^;&|]*" | head -1 || true)
[ -n "$segment" ] || exit 0

# Quoted text, such as a commit message, is not where flags live.
unquoted=$(printf '%s' "$segment" | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g")
if printf '%s' "$unquoted" | grep -qE -- '(^|[[:space:]])(--no-verify|-[a-zA-Z]*n[a-zA-Z]*)([[:space:]]|$)'; then
    echo "Blocked: git commit with --no-verify. Hooks are never skipped. Fix what the check reports instead." >&2
    exit 2
fi

# git -C <path> commits in that repository rather than the working directory.
repo=$(printf '%s' "$unquoted" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+).*/\1/p')
if [ -n "$repo" ]; then
    case "$repo" in
        /*) cwd=$repo ;;
        *) cwd=$cwd/$repo ;;
    esac
fi
cd "$cwd"

pre_commit=$(git rev-parse --git-path hooks/pre-commit 2>/dev/null || true)
if [ -n "$pre_commit" ] && [ -f "$pre_commit" ] && grep -q johns-way "$pre_commit"; then
    exit 0
fi

if ! output=$("$script_dir/check.sh" "$PWD" 2>&1); then
    printf 'Commit blocked: the check failed.\n%s\n' "$output" >&2
    exit 2
fi
