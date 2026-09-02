#!/usr/bin/env bash
# Prints the dependencies changed by the staged diff of the repository
# containing directory $1, one per line:
#
#   pypi <name> <version> <earliest upload time, or "unknown">
#   action <owner/repo> <ref>
#
# Python packages come from uv.lock: every registry package whose name and
# version pair is new. uv records an upload time for each file of a package,
# and the earliest is the release date. Actions come from "uses:" lines added
# to workflow files.
set -euo pipefail

cd "${1:-.}"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
cd "$(git rev-parse --show-toplevel)"

staged=$(git diff --cached --name-only)
[ -n "$staged" ] || exit 0

# Reads a uv.lock on stdin and prints "name version upload-time" per registry package.
lock_packages() {
    awk '
        function flush() {
            if (name != "" && registry) print name, version, (date == "" ? "unknown" : date)
            name = ""; version = ""; registry = 0; date = ""
        }
        /^\[\[package\]\]/ { flush(); next }
        /^name = / { name = $3; gsub(/"/, "", name) }
        /^version = / { version = $3; gsub(/"/, "", version) }
        /^source = .*registry/ { registry = 1 }
        /upload-time = "/ {
            match($0, /upload-time = "[^"]+"/)
            d = substr($0, RSTART + 15, RLENGTH - 16)
            if (date == "" || d < date) date = d
        }
        END { flush() }
    '
}

if printf '%s\n' "$staged" | grep -qx 'uv.lock'; then
    old_keys=$( (git show HEAD:uv.lock 2>/dev/null || true) | lock_packages | awk '{print $1, $2}')
    while read -r name version date; do
        [ -n "$name" ] || continue
        if ! printf '%s\n' "$old_keys" | grep -qxF "$name $version"; then
            echo "pypi $name $version $date"
        fi
    done < <(git show :uv.lock | lock_packages)
fi

while read -r file; do
    case "$file" in
        .github/workflows/*.yml | .github/workflows/*.yaml) ;;
        *) continue ;;
    esac
    git diff --cached -U0 -- "$file" \
        | grep -E '^\+.*uses:[[:space:]]*"?[^@"[:space:]]+@' \
        | sed -E 's/.*uses:[[:space:]]*"?([^@"[:space:]]+)@([^"[:space:]#]+).*/action \1 \2/' \
        || true
done <<< "$staged" | awk '!seen[$0]++'
