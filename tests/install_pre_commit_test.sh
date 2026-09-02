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
