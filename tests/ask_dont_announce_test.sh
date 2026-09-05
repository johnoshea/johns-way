#!/usr/bin/env bash
# Tests for hooks/ask-dont-announce.sh, the Stop hook.

root=${root:?set by tests/run.sh}

# Writes a transcript whose last assistant message is $1, then runs the hook.
# Prints the hook's stdout.
hook_with_last_message() {
    jq -nc --arg text "$1" '{type: "assistant", message: {content: [{type: "text", text: $text}]}}' > transcript.jsonl
    jq -n --arg path "$PWD/transcript.jsonl" --argjson active "${2:-false}" \
        '{hook_event_name: "Stop", transcript_path: $path, stop_hook_active: $active}' \
        | "$root/hooks/ask-dont-announce.sh"
}

test_announcing_a_decision_is_blocked() {
    output=$(hook_with_last_message "I will use option A unless you object.")
    assert_contains "$output" '"decision":"block"'
    assert_contains "$output" "AskUserQuestion"
}

test_a_plain_message_passes() {
    assert_eq "" "$(hook_with_last_message "Done. All 51 tests pass.")"
}

test_does_not_block_twice_in_a_row() {
    assert_eq "" "$(hook_with_last_message "I will use option A unless you object." true)"
}

test_missing_transcript_passes() {
    output=$(echo '{"transcript_path": "/nonexistent", "stop_hook_active": false}' | "$root/hooks/ask-dont-announce.sh")
    assert_eq "" "$output"
}

test_codex_last_message_blocks_without_transcript() {
    output=$(echo '{"last_assistant_message":"I will use A unless you object."}' | "$root/hooks/ask-dont-announce.sh")
    assert_contains "$output" '"decision":"block"'
}

test_codex_empty_last_message_does_not_read_old_transcript() {
    echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Unless you object"}]}}' > transcript.jsonl
    output=$(jq -n --arg path "$PWD/transcript.jsonl" '{last_assistant_message:"",transcript_path:$path}' | "$root/hooks/ask-dont-announce.sh")
    assert_eq "" "$output"
}

test_codex_stop_does_not_block_twice() {
    output=$(echo '{"last_assistant_message":"Unless you object", "stop_hook_active":true}' | "$root/hooks/ask-dont-announce.sh")
    assert_eq "" "$output"
}
