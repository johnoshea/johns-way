#!/usr/bin/env bash
# Tests for bin/johns-way-install-pre-commit.

root=${root:?set by tests/run.sh}

install() {
    "$root/bin/johns-way-install-pre-commit"
}

test_installs_an_executable_hook_that_runs_the_check() {
    make_repo
    install >/dev/null
    [ -x .git/hooks/pre-commit ]
    assert_contains "$(cat .git/hooks/pre-commit)" "johns-way"
    printf 'check:\n    echo "tests broke"; false\n' > justfile
    git add justfile
    output=$(git commit -q -m "x" 2>&1) && return 1
    assert_contains "$output" "tests broke"
}

test_reinstalling_over_our_own_hook_is_fine() {
    make_repo
    install >/dev/null
    install >/dev/null
}

test_refuses_to_overwrite_a_hook_that_is_not_ours() {
    make_repo
    printf '#!/usr/bin/env bash\ntrue\n' > .git/hooks/pre-commit
    output=$(install 2>&1) && return 1
    assert_contains "$output" "not ours"
    assert_eq "$(printf '#!/usr/bin/env bash\ntrue\n')" "$(cat .git/hooks/pre-commit)"
}

# Puts a stub check.sh at $1 that fails with the message $2, so that a commit
# shows which copy of the plugin the hook ran.
stub_check() {
    mkdir -p "$(dirname "$1")"
    printf '#!/usr/bin/env bash\necho "%s"; exit 1\n' "$2" > "$1"
    chmod +x "$1"
}

# Commits a change and prints the output of the failed commit.
failed_commit_output() {
    echo "x" >> README.md
    git add README.md
    git commit -q -m "x" 2>&1 && return 1
    return 0
}

test_hook_prefers_the_skills_directory_link() {
    make_repo
    export HOME=$PWD/home
    stub_check "$HOME/.claude/skills/johns-way/hooks/check.sh" "ran skills-dir copy"
    stub_check "$HOME/.claude/plugins/cache/johns-way/johns-way/0.2.0/hooks/check.sh" "ran cached copy"
    install >/dev/null
    assert_contains "$(failed_commit_output)" "ran skills-dir copy"
}

test_hook_runs_the_newest_cached_version() {
    make_repo
    export HOME=$PWD/home
    stub_check "$HOME/.claude/plugins/cache/johns-way/johns-way/0.9.0/hooks/check.sh" "ran 0.9.0"
    stub_check "$HOME/.claude/plugins/cache/johns-way/johns-way/0.10.0/hooks/check.sh" "ran 0.10.0"
    install >/dev/null
    assert_contains "$(failed_commit_output)" "ran 0.10.0"
}

test_hook_falls_back_to_the_copy_it_was_installed_from() {
    make_repo
    export HOME=$PWD/home
    mkdir plugin && cp -R "$root/bin" "$root/hooks" plugin/
    stub_check "$PWD/plugin/hooks/check.sh" "ran install copy"
    plugin/bin/johns-way-install-pre-commit >/dev/null
    assert_contains "$(failed_commit_output)" "ran install copy"
}

test_hook_reports_when_no_copy_of_the_plugin_exists() {
    make_repo
    export HOME=$PWD/home
    mkdir plugin && cp -R "$root/bin" "$root/hooks" plugin/
    plugin/bin/johns-way-install-pre-commit >/dev/null
    rm -rf plugin
    assert_contains "$(failed_commit_output)" "johns-way is not installed"
}
