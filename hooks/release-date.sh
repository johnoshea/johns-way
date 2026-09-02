#!/usr/bin/env bash
# Prints the release date of a dependency as an ISO 8601 UTC timestamp.
#
#   release-date.sh pypi <name> <version>       from PyPI
#   release-date.sh action <owner/repo> <ref>   from GitHub: the date of the
#                                               commit the ref points at
#
# Exits non-zero when the date cannot be found.
set -euo pipefail

kind=$1
name=$2
version=$3

case "$kind" in
    pypi)
        curl -fsS --max-time 15 "https://pypi.org/pypi/$name/$version/json" \
            | jq -er '[.urls[].upload_time_iso_8601] | sort | .[0]'
        ;;
    action)
        # A ref is a full commit sha, a tag, or a branch.
        if [[ $version =~ ^[0-9a-f]{40}$ ]]; then
            sha=$version
        else
            object=$(gh api "repos/$name/git/ref/tags/$version" 2>/dev/null \
                || gh api "repos/$name/git/ref/heads/$version")
            sha=$(printf '%s' "$object" | jq -er '.object.sha')
            if [ "$(printf '%s' "$object" | jq -r '.object.type')" = tag ]; then
                sha=$(gh api "repos/$name/git/tags/$sha" | jq -er '.object.sha')
            fi
        fi
        gh api "repos/$name/commits/$sha" | jq -er '.commit.committer.date'
        ;;
    *)
        echo "unknown dependency kind: $kind" >&2
        exit 1
        ;;
esac
