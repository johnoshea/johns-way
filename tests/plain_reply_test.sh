#!/usr/bin/env bash
# Tests for hooks/plain-reply.sh, the Stop hook that keeps replies to one
# idea per sentence.

root=${root:?set by tests/run.sh}

# Writes a transcript whose last assistant message is $1, then runs the hook.
# Prints the hook's stdout.
hook_with_last_message() {
    jq -nc --arg text "$1" '{type: "assistant", message: {content: [{type: "text", text: $text}]}}' > transcript.jsonl
    jq -n --arg path "$PWD/transcript.jsonl" --argjson active "${2:-false}" \
        '{hook_event_name: "Stop", transcript_path: $path, stop_hook_active: $active}' \
        | "$root/hooks/plain-reply.sh"
}

long="one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix."

test_a_sentence_over_25_words_is_blocked() {
    output=$(hook_with_last_message "Short one. $long")
    assert_contains "$output" '"decision":"block"'
    assert_contains "$output" "25 words"
    assert_contains "$output" "twentysix"
}

test_a_semicolon_in_prose_is_blocked() {
    output=$(hook_with_last_message "The hook runs first; the check runs second.")
    assert_contains "$output" '"decision":"block"'
    assert_contains "$output" "semicolon"
}

test_short_sentences_pass() {
    assert_eq "" "$(hook_with_last_message "Done. All 95 tests pass. The tree is clean.")"
}

test_a_fenced_code_block_is_not_checked() {
    assert_eq "" "$(hook_with_last_message "The output was:

\`\`\`
$long
error: a; b
\`\`\`

That is all.")"
}

test_inline_code_is_not_checked() {
    assert_eq "" "$(hook_with_last_message "Run \`a; b\` to see it.")"
}

test_a_table_row_is_not_checked() {
    assert_eq "" "$(hook_with_last_message "| $long | $long |")"
}

test_list_items_without_full_stops_are_separate_sentences() {
    assert_eq "" "$(hook_with_last_message "Files touched:
- one two three four five six seven eight nine ten eleven twelve thirteen
- one two three four five six seven eight nine ten eleven twelve thirteen")"
}

# Prints $1 five-word sentences, none of which trips the sentence check.
short_sentences() {
    for ((i = 0; i < $1; i++)); do printf 'one two three four five. '; done
}

test_a_reply_over_250_words_without_a_summary_heading_is_blocked() {
    output=$(hook_with_last_message "$(short_sentences 50) Done.")
    assert_contains "$output" '"decision":"block"'
    assert_contains "$output" "251 words"
    assert_contains "$output" "Summary"
}

test_a_reply_of_exactly_250_words_needs_no_summary() {
    assert_eq "" "$(hook_with_last_message "$(short_sentences 50)")"
}

test_a_long_reply_that_opens_with_a_summary_heading_passes() {
    assert_eq "" "$(hook_with_last_message "## Summary

$(short_sentences 60)")"
}

test_a_summary_heading_below_another_heading_does_not_count() {
    output=$(hook_with_last_message "## Evidence

$(short_sentences 60)

## Summary

It broke.")
    assert_contains "$output" '"decision":"block"'
}

test_words_in_a_code_block_do_not_count_towards_the_250() {
    assert_eq "" "$(hook_with_last_message "The output was:

\`\`\`
$(short_sentences 60)
\`\`\`

That is all.")"
}

test_a_long_sentence_and_a_missing_summary_are_reported_together() {
    output=$(hook_with_last_message "$(short_sentences 50) $long")
    assert_contains "$output" "25 words"
    assert_contains "$output" "first heading is not Summary"
}

test_does_not_block_twice_in_a_row() {
    assert_eq "" "$(hook_with_last_message "$long" true)"
}
