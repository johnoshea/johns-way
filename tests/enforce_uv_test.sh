#!/usr/bin/env bash
# Tests for hooks/enforce-uv.sh, the PreToolUse hook on Bash.

root=${root:?set by tests/run.sh}

# Runs the hook with a Bash tool command. Prints stderr; returns the exit code.
hook() {
    { jq -n --arg cmd "$1" '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $cmd}}' \
        | "$root/hooks/enforce-uv.sh" >/dev/null; } 2>&1
}

test_direct_python_is_blocked() {
    code=0; output=$(hook "python3 -c 'print(1)'") || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "uv run python"
    code=0; output=$(hook "cd x && python script.py") || code=$?
    assert_eq 2 "$code"
}

test_pip_is_blocked() {
    code=0; output=$(hook "pip install requests") || code=$?
    assert_eq 2 "$code"
    code=0; output=$(hook "uv pip install requests") || code=$?
    assert_eq 2 "$code"
}

test_uv_run_python_is_allowed() {
    hook "uv run python -c 'print(1)'"
    hook "uv run pytest"
    hook "uv add requests"
}

test_unrelated_commands_are_allowed() {
    hook "ls -la"
    hook "git status"
}
