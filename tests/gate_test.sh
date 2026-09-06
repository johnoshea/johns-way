#!/usr/bin/env bash
# Tests for hooks/gate.sh, the hook that holds the session at a gate.
# tests/run.sh sets CLAUDE_PLUGIN_DATA to a fresh directory for every test.

root=${root:?set by tests/run.sh}

gate_file() {
    echo "$CLAUDE_PLUGIN_DATA/sessions/s1.gate"
}

# Runs the Stop event with $1 as the last assistant message.
stop_with_message() {
    jq -n --arg text "$1" '{hook_event_name: "Stop", session_id: "s1", last_assistant_message: $text}' \
        | "$root/hooks/gate.sh"
}

# Runs the PreToolUse event for tool $1 with tool input JSON $2.
# Prints stderr; returns the hook's exit code.
pre_tool() {
    { jq -n --arg tool "$1" --argjson input "$2" \
        '{hook_event_name: "PreToolUse", session_id: "s1", tool_name: $tool, tool_input: $input}' \
        | "$root/hooks/gate.sh" >/dev/null; } 2>&1
}

# Runs the PostToolUse event for a Bash command $1 whose response was $2.
post_bash() {
    jq -n --arg cmd "$1" --arg resp "$2" \
        '{hook_event_name: "PostToolUse", session_id: "s1", tool_name: "Bash", tool_input: {command: $cmd}, tool_response: $resp}' \
        | "$root/hooks/gate.sh"
}

# Runs the UserPromptSubmit event with prompt $1. Prints the added context.
prompt() {
    jq -n --arg p "$1" '{hook_event_name: "UserPromptSubmit", session_id: "s1", prompt: $p}' \
        | "$root/hooks/gate.sh" \
        | jq -r '.hookSpecificOutput.additionalContext // empty'
}

task_notice() {
    printf '<task-notification>\n<task-id>%s</task-id>\n<status>completed</status>\n</task-notification>' "$1"
}

open_gate() {
    stop_with_message $'Findings above.\n\n```\ncrit\n```'
}

test_printing_the_crit_command_opens_the_gate() {
    open_gate
    assert_eq gate "$(cat "$(gate_file)")"
}

test_a_crit_command_with_a_path_opens_the_gate() {
    stop_with_message $'Spec committed.\n\n```\ncrit docs/specs/2026-09-06-topic.md\n```'
    assert_eq gate "$(cat "$(gate_file)")"
}

test_an_ordinary_message_opens_no_gate() {
    stop_with_message "Done. All tests pass. Run crit when you like."
    [ ! -f "$(gate_file)" ]
}

test_stop_reads_the_transcript_when_no_message_is_supplied() {
    jq -nc '{type: "assistant", message: {content: [{type: "text", text: "```\ncrit\n```"}]}}' > transcript.jsonl
    jq -n --arg path "$PWD/transcript.jsonl" '{hook_event_name: "Stop", session_id: "s1", transcript_path: $path}' \
        | "$root/hooks/gate.sh"
    assert_eq gate "$(cat "$(gate_file)")"
}

test_tool_calls_are_blocked_while_the_gate_is_open() {
    open_gate
    output=$(pre_tool Bash '{"command": "cat out.txt"}'); code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "gate is open"
}

test_asking_a_question_is_allowed_at_the_gate() {
    open_gate
    pre_tool AskUserQuestion '{"questions": []}'
}

test_without_a_gate_tools_are_allowed() {
    pre_tool Bash '{"command": "ls"}'
}

test_the_users_message_closes_the_gate() {
    open_gate
    assert_eq "" "$(prompt "Looks fine, apply 1 to 4.")"
    [ ! -f "$(gate_file)" ]
    pre_tool Bash '{"command": "ls"}'
}

test_a_task_notice_keeps_the_gate_and_tells_the_model_to_hold() {
    open_gate
    output=$(prompt "$(task_notice abc)")
    assert_contains "$output" "gate is open"
    [ -f "$(gate_file)" ]
    output=$(pre_tool Bash '{"command": "cat out.txt"}'); code=$?
    assert_eq 2 "$code"
}

test_a_task_notice_without_a_gate_passes() {
    assert_eq "" "$(prompt "$(task_notice abc)")"
}

test_a_background_crit_run_holds_until_that_run_finishes() {
    post_bash "crit --range a..b" "Command running in background with ID: bwm1. Output is being written to: $PWD/bwm1.output. You will be notified when it completes."
    [ -f "$(gate_file)" ]
    pre_tool Bash "{\"command\": \"sleep 2; head -3 $PWD/bwm1.output\"}"
    pre_tool Read "{\"file_path\": \"$PWD/bwm1.output\"}"
    pre_tool TaskOutput '{"task_id": "bwm1"}'
    output=$(pre_tool Bash '{"command": "uv run pytest"}'); code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "crit"
    output=$(prompt "$(task_notice other)")
    assert_contains "$output" "crit"
    [ -f "$(gate_file)" ]
    assert_eq "" "$(prompt "$(task_notice bwm1)")"
    [ ! -f "$(gate_file)" ]
}

test_a_foreground_crit_command_opens_no_gate() {
    post_bash "crit comments --json" '[{"id": "c_1"}]'
    [ ! -f "$(gate_file)" ]
}

test_session_start_clears_the_gate() {
    open_gate
    echo '{"hook_event_name": "SessionStart", "session_id": "s1"}' | "$root/hooks/session-start.sh" >/dev/null
    [ ! -f "$(gate_file)" ]
}

test_compaction_keeps_the_gate() {
    open_gate
    echo '{"hook_event_name": "SessionStart", "session_id": "s1", "source": "compact"}' | "$root/hooks/session-start.sh" >/dev/null
    [ -f "$(gate_file)" ]
}
