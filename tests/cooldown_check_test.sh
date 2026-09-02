#!/usr/bin/env bash
# Tests for hooks/cooldown-check.sh, with a stub in place of release-date.sh.

root=${root:?set by tests/run.sh}

# The stub answers "action actions/checkout v5" with a fixed old date and
# "pypi old 1.0.0" with a fixed old date. Anything else is a lookup failure.
make_stub() {
    cat > stub.sh <<'EOF'
#!/usr/bin/env bash
case "$1 $2 $3" in
    "action actions/checkout v5") echo "2020-01-01T00:00:00Z" ;;
    "pypi old 1.0.0") echo "2020-01-01T00:00:00Z" ;;
    *) echo "no date for $*" >&2; exit 1 ;;
esac
EOF
    chmod +x stub.sh
    export JOHNS_WAY_RELEASE_DATE=$PWD/stub.sh
}

check() {
    "$root/hooks/cooldown-check.sh" "$PWD"
}

days_ago() {
    date -u -v-"$1"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "$1 days ago" +%Y-%m-%dT%H:%M:%SZ
}

stage_lock_with() {
    cat > uv.lock <<EOF
[[package]]
name = "$1"
version = "$2"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://x/$1.tar.gz", hash = "sha256:a", size = 1, upload-time = "$3" }
EOF
    git add uv.lock
}

test_nothing_staged_passes() {
    make_repo
    make_stub
    check
}

test_version_older_than_fourteen_days_passes() {
    make_repo
    make_stub
    stage_lock_with ruff 0.12.0 "$(days_ago 15)"
    check
}

test_version_newer_than_fourteen_days_fails_and_names_it() {
    make_repo
    make_stub
    stage_lock_with ruff 0.13.0 "$(days_ago 3)"
    output=$(check 2>&1) && return 1
    assert_contains "$output" "ruff 0.13.0"
    assert_contains "$output" "14 days"
}

test_unknown_upload_time_is_looked_up() {
    make_repo
    make_stub
    cat > uv.lock <<'EOF'
[[package]]
name = "old"
version = "1.0.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://x/old.tar.gz", hash = "sha256:a", size = 1 }
EOF
    git add uv.lock
    check
}

test_lookup_failure_fails_closed() {
    make_repo
    make_stub
    cat > uv.lock <<'EOF'
[[package]]
name = "mystery"
version = "1.0.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://x/m.tar.gz", hash = "sha256:a", size = 1 }
EOF
    git add uv.lock
    output=$(check 2>&1) && return 1
    assert_contains "$output" "mystery 1.0.0"
}

test_failure_to_enumerate_dependencies_fails_closed() {
    make_stub
    "$root/hooks/cooldown-check.sh" "$PWD/nonexistent" 2>/dev/null && return 1
    return 0
}

test_action_dates_are_looked_up() {
    make_repo
    make_stub
    mkdir -p .github/workflows
    printf 'steps:\n  - uses: actions/checkout@v5\n' > .github/workflows/ci.yml
    git add .github
    check
}
