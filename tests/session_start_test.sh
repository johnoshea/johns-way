#!/usr/bin/env bash
# Tests for hooks/session-start.sh.

root=${root:?set by tests/run.sh}

# Runs the hook the way Claude Code does: hook input as JSON on stdin.
# Prints the injected context.
run_hook() {
    jq -n --arg cwd "$PWD" '{hook_event_name: "SessionStart", cwd: $cwd}' \
        | "$root/hooks/session-start.sh" \
        | jq -r '.hookSpecificOutput | select(.hookEventName == "SessionStart") | .additionalContext'
}

test_injects_the_routing_skill_without_its_frontmatter() {
    context=$(run_hook)
    assert_contains "$context" "# Routing"
    assert_not_contains "$context" "name: routing"
    assert_not_contains "$context" "description:"
}

test_includes_the_session_status_when_there_is_something_to_report() {
    make_repo
    echo "changed" >> README.md
    context=$(run_hook)
    assert_contains "$context" "## Session status"
    assert_contains "$context" "Tracked files with uncommitted changes: 1"
}

test_omits_the_session_status_when_there_is_nothing_to_report() {
    make_repo
    assert_not_contains "$(run_hook)" "## Session status"
}

test_falls_back_to_the_working_directory_without_cwd_in_the_input() {
    make_repo
    echo "changed" >> README.md
    context=$(echo '{}' | "$root/hooks/session-start.sh" | jq -r '.hookSpecificOutput.additionalContext')
    assert_contains "$context" "Tracked files with uncommitted changes: 1"
}
