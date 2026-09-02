#!/usr/bin/env bash
# Fails when any dependency staged in the repository containing directory $1
# was released under 14 days ago. Release dates come from uv.lock where it
# records them. The rest are looked up with release-date.sh, or with the
# command named in JOHNS_WAY_RELEASE_DATE, which tests use for a stub.
# A version whose date cannot be found fails the check.
set -euo pipefail

cooldown_days=14
script_dir=$(cd "$(dirname "$0")" && pwd)
lookup=${JOHNS_WAY_RELEASE_DATE:-$script_dir/release-date.sh}

threshold=$(date -u -v-${cooldown_days}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -d "$cooldown_days days ago" +%Y-%m-%dT%H:%M:%SZ)

violations=""
failures=""
while read -r kind name version date; do
    [ -n "$kind" ] || continue
    if [ "$kind" = action ] || [ "${date:-unknown}" = unknown ]; then
        if ! date=$("$lookup" "$kind" "$name" "$version" 2>/dev/null); then
            failures="$failures
  $name $version"
            continue
        fi
    fi
    if [[ "${date:0:19}" > "${threshold:0:19}" ]]; then
        violations="$violations
  $name $version, released $date"
    fi
done < <("$script_dir/changed-dependencies.sh" "${1:-.}")

if [ -n "$failures" ]; then
    echo "Dependency cooldown: no release date could be found for these versions, so they cannot be verified:$failures" >&2
fi
if [ -n "$violations" ]; then
    echo "Dependency cooldown: these versions are under $cooldown_days days old:$violations" >&2
fi
[ -z "$failures$violations" ]
