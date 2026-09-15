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
    code=0; output=$(hook 'git commit -m "x"') || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "tests broke"
}

test_git_commit_passes_when_the_check_passes() {
    make_repo
    printf 'check:\n    true\n' > justfile
    hook 'git add -A && git commit -m "x"'
}

test_git_commit_with_dash_c_checks_that_repository() {
    make_repo
    printf 'check:\n    true\n' > justfile
    mkdir other && (cd other && make_repo && failing_justfile)
    code=0; output=$(hook "git -C $PWD/other commit -m x") || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "tests broke"
}

test_no_verify_is_only_looked_for_in_the_commit_itself() {
    make_repo
    printf 'check:\n    true\n' > justfile
    hook 'git commit -m "x" && git log -n 1'
    hook 'git commit -m "Add -n flag"; ls -n'
}

test_runs_the_check_from_a_subdirectory() {
    make_repo
    failing_justfile
    mkdir sub && cd sub || return 1
    code=0; output=$(hook 'git commit -m "x"') || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "tests broke"
}

test_skips_for_our_pre_commit_hook_from_a_subdirectory() {
    make_repo
    failing_justfile
    printf '#!/usr/bin/env bash\n# Installed by johns-way.\nexec /nonexistent/check.sh\n' > .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    mkdir sub && cd sub || return 1
    hook 'git commit -m "x"'
}

test_no_verify_is_blocked_outright() {
    make_repo
    printf 'check:\n    true\n' > justfile
    code=0; output=$(hook 'git commit --no-verify -m "x"') || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "never skipped"
    code=0; output=$(hook 'git commit -n -m "x"') || code=$?
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
    code=0; output=$(hook 'git commit -m "x"') || code=$?
    assert_eq 2 "$code"
}

test_blocks_a_message_with_a_sentence_over_25_words() {
    make_repo
    printf 'check:\n    true\n' > justfile
    long="one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix."
    code=0; output=$(hook "git commit -m \"$long\"") || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "25 words"
}

test_blocks_a_message_with_a_semicolon() {
    make_repo
    printf 'check:\n    true\n' > justfile
    code=0; output=$(hook 'git commit -m "Add the thing; remove the other"') || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "semicolon"
}

test_reads_a_heredoc_message_and_joins_its_wrapped_lines() {
    make_repo
    printf 'check:\n    true\n' > justfile
    # shellcheck disable=SC2016 # the string is the literal command the hook reads
    cmd='git commit -m "$(cat <<'"'"'EOF'"'"'
Add the thing

one two three four five six seven eight nine ten eleven twelve thirteen
fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone
twentytwo twentythree twentyfour twentyfive twentysix.
EOF
)"'
    code=0; output=$(hook "$cmd") || code=$?
    assert_eq 2 "$code"
    assert_contains "$output" "25 words"
}

test_passes_a_message_of_short_sentences() {
    make_repo
    printf 'check:\n    true\n' > justfile
    # shellcheck disable=SC2016 # the string is the literal command the hook reads
    cmd='git commit -m "$(cat <<'"'"'EOF'"'"'
Add the thing to the module and the other thing too

one two three four five six seven eight nine ten eleven twelve thirteen
fourteen fifteen sixteen seventeen eighteen nineteen twenty. one two
three four five six seven eight nine ten eleven twelve thirteen fourteen
fifteen sixteen seventeen eighteen nineteen twenty.

one two three four five six seven eight nine ten eleven twelve thirteen
fourteen fifteen sixteen seventeen eighteen nineteen twenty

Co-Authored-By: Someone <someone@example.com>
EOF
)"'
    hook "$cmd"
}
