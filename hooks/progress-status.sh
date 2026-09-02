#!/usr/bin/env bash
# Prints the progress status of the repository containing directory $1:
# one line per spec with unfinished tasks, and one line if tracked files have
# uncommitted changes. Prints nothing when there is nothing to report.
#
# A spec is a file under docs/specs/. Its tasks are the lines starting with a
# number and a period under the "## Tasks" heading. A task is done when a
# commit carries the trailers "Spec: <path>" and "Task: <number>".
set -euo pipefail

cd "${1:-.}"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
cd "$(git rev-parse --show-toplevel)"

# Task numbers already committed for the spec at $1, one per line.
done_tasks() {
    git rev-parse --verify HEAD >/dev/null 2>&1 || return 0
    local pattern="^Spec: ${1//./\\.}\$"
    git log --format='%(trailers:key=Task,valueonly)' --grep="$pattern" \
        | grep -E '^[0-9]+$' | sort -un || true
}

for spec in docs/specs/*.md; do
    [ -e "$spec" ] || continue
    tasks=$(awk '/^## /{in_tasks = ($0 == "## Tasks")} in_tasks && /^[0-9]+\. /' "$spec")
    [ -n "$tasks" ] || continue
    total=$(printf '%s\n' "$tasks" | wc -l | tr -d ' ')
    done=$(done_tasks "$spec")
    done_count=$(printf '%s\n' "$done" | grep -c . || true)
    next=""
    while IFS= read -r task; do
        number=${task%%.*}
        if ! printf '%s\n' "$done" | grep -qx "$number"; then
            next=$task
            break
        fi
    done <<< "$tasks"
    [ -n "$next" ] || continue
    echo "Spec $spec: $done_count of $total tasks done. Next: $next"
done

changed=$(git status --porcelain --untracked-files=no | wc -l | tr -d ' ')
if [ "$changed" -gt 0 ]; then
    echo "Tracked files with uncommitted changes: $changed"
fi
