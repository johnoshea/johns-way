#!/usr/bin/env bash
# Stop hook: catch a turn that announced a decision instead of asking for one.
#
# John's rule (global CLAUDE.md, "Human review gates"): when a choice is his to
# make, ask it with AskUserQuestion and wait. Announcing a pick and inviting an
# objection is not asking — he may not see it, and interrupting costs him far
# more than one turn costs Claude.
#
# This reads only the MOST RECENT assistant message. Matching the whole
# transcript would fire forever once any of these phrases appeared, including
# in a conversation about the phrases themselves.
set -uo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
input=$(cat)

# stop_hook_active means this hook already blocked once and Claude is coming
# back round. Blocking again is how a Stop hook turns into an infinite loop.
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || exit 0
[ "$active" = "true" ] && exit 0

last=$(printf '%s' "$input" | "$script_dir/last-message.sh")
[ -z "$last" ] && exit 0

# High-precision tells only. Each of these reads as "I made your decision and
# am giving you the chance to overrule me", which is the exact failure.
tells="say the word\
|shout if you\
|unless you object\
|unless you'd prefer\
|unless you say otherwise\
|unless you tell me otherwise\
|let me know if you'd rather\
|let me know if you'd prefer\
|let me know if you want me to do it differently\
|happy to switch if"

if printf '%s' "$last" | grep -Eqi "$tells"; then
  cat <<'JSON'
{"decision":"block","reason":"Your message ends by announcing a decision and inviting John to object. That is a question you chose not to ask.\n\nHis CLAUDE.md, under Human review gates: when a choice is his to make, ask it with AskUserQuestion and wait. Announcing your pick is not asking. He may not see the line, and interrupting you costs him far more than one turn costs you.\n\nDo one of these, then finish:\n1. If the choice really is his, call AskUserQuestion and stop there.\n2. If a rule or constraint blocks one option, say so and ask how he wants to proceed. A constraint that stops you doing something is never permission to decide for him.\n3. If it was never his call, delete the hedge and state the decision plainly."}
JSON
fi

exit 0
