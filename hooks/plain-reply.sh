#!/usr/bin/env bash
# Stop hook: block a turn whose last message has a sentence over 25 words or
# a semicolon, and send the model back to rewrite those sentences.
#
# John's rule (global CLAUDE.md, "Writing style"): one idea per sentence,
# about 20 words. A packed sentence costs him a second read. The check is
# mechanical on purpose; long-sentences.sh holds it and the commit check
# applies the same rule to commit messages.
set -uo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
input=$(cat)

# stop_hook_active means a Stop hook already blocked once and Claude is
# coming back round. Blocking again is how a Stop hook becomes a loop.
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || exit 0
[ "$active" = "true" ] && exit 0

last=$(printf '%s' "$input" | "$script_dir/last-message.sh")
[ -z "$last" ] && exit 0

long=$(printf '%s\n' "$last" | "$script_dir/long-sentences.sh")
[ -z "$long" ] && exit 0

# shellcheck disable=SC2016 # $long is a jq variable
jq -nc --arg long "$long" '{decision: "block",
  reason: ("Your last message has a sentence over 25 words or a semicolon. One idea per sentence, about 20 words, for a reader who was not in the session. Rewrite these sentences, keep everything else, and finish:\n\n" + $long)}'
exit 0
