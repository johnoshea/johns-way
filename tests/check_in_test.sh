#!/usr/bin/env bash
# Tests for hooks/check-in.sh, the PostToolUse session check-in.
# tests/run.sh sets CLAUDE_PLUGIN_DATA to a fresh directory for every test.

root=${root:?set by tests/run.sh}

# Records a session start $1 minutes ago, the way session-start.sh does.
started_minutes_ago() {
    mkdir -p "$CLAUDE_PLUGIN_DATA/sessions"
    echo $(( $(date +%s) - $1 * 60 )) > "$CLAUDE_PLUGIN_DATA/sessions/s1.start"
}

check_in() {
    echo '{"hook_event_name": "PostToolUse", "session_id": "s1", "tool_name": "Bash"}' \
        | "$root/hooks/check-in.sh" \
        | jq -r '.hookSpecificOutput.additionalContext // empty'
}

test_no_start_record_prints_nothing() {
    assert_eq "" "$(check_in)"
}

test_before_the_limit_prints_nothing() {
    started_minutes_ago 30
    assert_eq "" "$(check_in)"
}

test_after_the_limit_delivers_the_check_in_once() {
    started_minutes_ago 61
    first=$(check_in)
    assert_contains "$first" "Session check-in"
    assert_contains "$first" "AskUserQuestion"
    assert_eq "" "$(check_in)"
}

test_the_limit_is_configurable() {
    started_minutes_ago 5
    assert_eq "" "$(check_in)"
    assert_contains "$(JOHNS_WAY_CHECKIN_MINUTES=4 check_in)" "Session check-in"
}

test_compaction_keeps_the_start_time() {
    started_minutes_ago 61
    echo '{"hook_event_name": "SessionStart", "session_id": "s1", "source": "compact"}' | "$root/hooks/session-start.sh" >/dev/null
    assert_contains "$(check_in)" "Session check-in"
}

test_session_start_records_the_start_and_clears_a_previous_notification() {
    mkdir -p "$CLAUDE_PLUGIN_DATA/sessions"
    touch "$CLAUDE_PLUGIN_DATA/sessions/s1.notified"
    echo '{"hook_event_name": "SessionStart", "session_id": "s1"}' | "$root/hooks/session-start.sh" >/dev/null
    [ -f "$CLAUDE_PLUGIN_DATA/sessions/s1.start" ]
    [ ! -f "$CLAUDE_PLUGIN_DATA/sessions/s1.notified" ]
    assert_eq "" "$(check_in)"
}
