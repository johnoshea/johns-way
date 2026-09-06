#!/usr/bin/env bash
# The gate hook: holds the session while a gate waits for the user.
#
# A gate is open from the moment the model prints the crit command on a line
# of its own until the user's next message. A background task that finishes
# meanwhile is delivered as a prompt, and the model treats it as work. So the
# hook blocks tool calls while the gate is open and tells the model to reply
# in one line and print the command again.
#
# One script serves four events. The state lives in one file per session
# under the plugin data directory, holding either "gate" or "crit <task id>"
# for a background crit run in progress.
set -uo pipefail

input=$(cat)
event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty')
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$session_id" ] || exit 0

sessions=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/johns-way}/sessions
gate=$sessions/$session_id.gate

field() {
    printf '%s' "$input" | jq -r "$1 // \"\""
}

open_gate() {
    mkdir -p "$sessions"
    printf '%s\n' "$1" > "$gate"
}

# The last assistant message: supplied directly by Codex and current Claude
# Code, else read from the transcript tail.
last_message() {
    if printf '%s' "$input" | jq -e 'has("last_assistant_message")' >/dev/null; then
        field .last_assistant_message
        return
    fi
    local transcript
    transcript=$(field .transcript_path)
    [ -f "$transcript" ] || return 0
    tail -n 400 "$transcript" 2>/dev/null \
        | jq -R 'fromjson? // empty' 2>/dev/null \
        | jq -s -r '[.[] | select(.type == "assistant") | .message.content[]?
            | select(.type == "text") | .text] | last // ""' 2>/dev/null
}

case $event in
Stop)
    # A crit round in progress keeps its record, so that its own notice still closes the gate.
    if [ -f "$gate" ] && grep -q '^crit ' "$gate"; then
        exit 0
    fi
    if last_message | grep -Eq '^[[:space:]]*crit([[:space:]]+[^[:space:]]+)?[[:space:]]*$'; then
        open_gate gate
    fi
    ;;
PreToolUse)
    [ -f "$gate" ] || exit 0
    tool=$(field .tool_name)
    [ "$tool" = AskUserQuestion ] && exit 0
    read -r kind task < "$gate"
    if [ "$kind" = crit ]; then
        [ "$tool" = TaskOutput ] && exit 0
        case "$(field .tool_input.command) $(field .tool_input.file_path)" in
        *"/$task.output"*) exit 0 ;;
        esac
        echo "Blocked by the gate hook: a crit round is open. Wait for the crit task ($task) to finish. Only its output file, $task.output, may be read." >&2
        exit 2
    fi
    echo "Blocked by the gate hook: a gate is open and the user has not replied. Reply in one line and print the gate command again. Tool calls resume after the user's next message." >&2
    exit 2
    ;;
PostToolUse)
    [ "$(field .tool_name)" = Bash ] || exit 0
    field .tool_input.command | grep -Eq '^[[:space:]]*crit([[:space:]]|$)' || exit 0
    # A command that runs in the background answers with its task id in place of output.
    task=$(printf '%s' "$input" | jq -r '.tool_response.backgroundTaskId? // ""')
    [ -n "$task" ] || exit 0
    open_gate "crit $task"
    ;;
UserPromptSubmit)
    prompt=$(field .prompt)
    if ! printf '%s' "$prompt" | grep -q '^<task-notification>'; then
        rm -f "$gate"
        exit 0
    fi
    [ -f "$gate" ] || exit 0
    read -r kind task _ < "$gate"
    finished=$(printf '%s' "$prompt" | sed -nE 's/.*<task-id>([^<]+)<\/task-id>.*/\1/p' | head -n 1)
    if [ "$kind" = crit ]; then
        if [ "$finished" = "$task" ]; then
            rm -f "$gate"
            exit 0
        fi
        context="A crit round is open. Say in one line that this task finished and keep waiting for crit. Tool calls are blocked until the crit task finishes."
    else
        context="A gate is open and the user has not replied. Say in one line that this task finished and print the gate command again. Tool calls are blocked until the user's next message."
    fi
    jq -n --arg context "$context" \
        '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $context}}'
    ;;
esac

exit 0
