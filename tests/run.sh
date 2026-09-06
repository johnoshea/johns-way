#!/usr/bin/env bash
# Runs every function named test_* in tests/*_test.sh.
# Each test runs in its own empty temporary directory, in a subshell, so a
# failing test cannot affect the next one.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
export root

# shellcheck source=tests/helpers.sh
source "$root/tests/helpers.sh"

count=0
failures=0
for file in "$root"/tests/*_test.sh; do
    # shellcheck source=/dev/null
    source "$file"
    for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do
        count=$((count + 1))
        tmp=$(mktemp -d)
        export CLAUDE_PLUGIN_DATA="$tmp/plugin-data"
        # errexit inside the subshell makes the first failing assertion end the test.
        # Bash ignores errexit inside an if condition, so the subshell runs on its own line.
        (cd "$tmp" || exit 1; set -e; "$fn")
        status=$?
        if [ "$status" -eq 0 ]; then
            echo "ok   $fn"
        else
            echo "FAIL $fn"
            failures=$((failures + 1))
        fi
        rm -rf "$tmp"
        unset -f "$fn"
    done
done

echo "$count tests, $failures failures"
[ "$failures" -eq 0 ]
