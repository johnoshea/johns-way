#!/usr/bin/env bash
# Tests for hooks/check.sh, the check shared by the commit hook and the
# repository pre-commit hook.

root=${root:?set by tests/run.sh}

check() {
    JOHNS_WAY_RELEASE_DATE=/usr/bin/false "$root/hooks/check.sh" "$PWD"
}

test_repo_without_a_check_target_passes() {
    make_repo
    check
}

test_justfile_check_recipe_passing() {
    make_repo
    printf 'check:\n    true\n' > justfile
    check
}

test_justfile_check_recipe_failing_fails_with_its_output() {
    make_repo
    printf 'check:\n    echo "tests broke"; false\n' > justfile
    output=$(check 2>&1) && return 1
    assert_contains "$output" "tests broke"
}

test_justfile_without_a_check_recipe_passes() {
    make_repo
    printf 'build:\n    true\n' > justfile
    check
}

test_cooldown_violation_fails_before_the_check_target() {
    make_repo
    printf 'check:\n    echo "ran check"\n' > justfile
    cat > uv.lock <<EOF
[[package]]
name = "ruff"
version = "9.9.9"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://x/r.tar.gz", hash = "sha256:a", size = 1, upload-time = "$(date -u +%Y-%m-%dT%H:%M:%SZ)" }
EOF
    git add uv.lock
    output=$(check 2>&1) && return 1
    assert_contains "$output" "ruff 9.9.9"
    assert_not_contains "$output" "ran check"
}
