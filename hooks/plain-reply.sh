#!/usr/bin/env bash
# Stop hook: block a turn whose last message is hard to act on, and send the
# model back to rewrite it. Two checks, reported together:
#
# - A sentence over 25 words or a semicolon. John's rule (global CLAUDE.md,
#   "Writing style"): one idea per sentence, about 20 words. A packed
#   sentence costs him a second read. long-sentences.sh holds the check and
#   the commit check applies the same rule to commit messages.
# - Over 250 words whose first heading is not Summary. A long reply that
#   opens with its evidence leaves the reader hunting for what to do.
#
# Both checks are mechanical on purpose.
set -uo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
input=$(cat)

# stop_hook_active means a Stop hook already blocked once and Claude is
# coming back round. Blocking again is how a Stop hook becomes a loop.
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || exit 0
[ "$active" = "true" ] && exit 0

last=$(printf '%s' "$input" | "$script_dir/last-message.sh")
[ -z "$last" ] && exit 0

reason=""

long=$(printf '%s\n' "$last" | "$script_dir/long-sentences.sh")
if [ -n "$long" ]; then
    reason="Your last message has a sentence over 25 words or a semicolon. One idea per sentence, about 20 words, for a reader who was not in the session. Rewrite these sentences, keep everything else, and finish:

$long"
fi

# Prints the word count when the message is over the limit and its first
# heading is not Summary. Fenced code blocks and table rows are not counted.
words=$(printf '%s\n' "$last" | awk '
    /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }
    fenced { next }
    /^[[:space:]]*\|/ { next }
    /^#+[[:space:]]/ && !heading { heading = tolower($0) }
    { words += NF }
    END { if (words > 250 && heading !~ /^#+[[:space:]]+summary/) print words }
')
if [ -n "$words" ]; then
    [ -n "$reason" ] && reason+="

"
    reason+="Your last message has $words words and its first heading is not Summary. Over 250 words, the reader must learn what to do before reading the detail. Open with a Summary heading and a few short sentences: what happened, whether anything is at risk, and what the reader should do. Then cut the detail nobody asked for."
fi

[ -z "$reason" ] && exit 0

# shellcheck disable=SC2016 # $reason is a jq variable
jq -nc --arg reason "$reason" '{decision: "block", reason: $reason}'
exit 0
