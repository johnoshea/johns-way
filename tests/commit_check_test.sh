#!/usr/bin/env bash
# Tests for hooks/commit-check.sh, the PreToolUse hook on Bash.

root=${root:?set by tests/run.sh}

# Runs the hook with a Bash tool command. Prints stderr; returns the exit code.
hook() {
    { jq -n --arg cmd "$1" --arg cwd "$PWD" \
        '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}' \
        | "$root/hooks/commit-check.sh" >/dev/null; } 2>&1
}

failing_justfile() {
    printf 'check:\n    echo "tests broke"; false\n' > justfile
}

test_commands_other_than_git_commit_pass_without_running_the_check() {
    make_repo
    failing_justfile
    hook "ls -la"
    hook "git status"
    hook "git log --oneline | grep commit"
}

test_git_commit_runs_the_check_and_blocks_on_failure() {
    make_repo
    failing_justfile
    output=$(hook 'git commit -m "x"'); code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "tests broke"
}

test_git_commit_passes_when_the_check_passes() {
    make_repo
    printf 'check:\n    true\n' > justfile
    hook 'git add -A && git commit -m "x"'
}

test_git_commit_with_dash_c_is_recognised() {
    make_repo
    failing_justfile
    output=$(hook "git -C $PWD commit -m x"); code=$?
    assert_eq 2 "$code"
}

test_no_verify_is_blocked_outright() {
    make_repo
    printf 'check:\n    true\n' > justfile
    output=$(hook 'git commit --no-verify -m "x"'); code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "never skipped"
    output=$(hook 'git commit -n -m "x"'); code=$?
    assert_eq 2 "$code"
}

test_skips_when_the_repository_pre_commit_hook_is_ours() {
    make_repo
    failing_justfile
    printf '#!/usr/bin/env bash\n# Installed by johns-way.\nexec /nonexistent/check.sh\n' > .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    hook 'git commit -m "x"'
}

test_does_not_skip_for_another_pre_commit_hook() {
    make_repo
    failing_justfile
    printf '#!/usr/bin/env bash\ntrue\n' > .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    output=$(hook 'git commit -m "x"'); code=$?
    assert_eq 2 "$code"
}
