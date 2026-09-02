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

# Puts a stub uv on the PATH that records its arguments in uv.log.
stub_uv() {
    mkdir -p stubbin
    printf '#!/usr/bin/env bash\necho "$*" >> "%s/uv.log"\n' "$PWD" > stubbin/uv
    chmod +x stubbin/uv
    export PATH=$PWD/stubbin:$PATH
}

test_pyproject_without_a_justfile_runs_pytest_and_ruff_through_uv() {
    make_repo
    stub_uv
    printf '[project]\nname = "t"\nversion = "0"\n' > pyproject.toml
    check
    assert_eq "run pytest -q
run ruff check ." "$(cat uv.log)"
}

test_pyproject_at_the_repository_root_is_found_from_a_subdirectory() {
    make_repo
    stub_uv
    printf '[project]\nname = "t"\nversion = "0"\n' > pyproject.toml
    mkdir sub && cd sub || return 1
    check
    assert_contains "$(cat ../uv.log)" "run pytest -q"
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
