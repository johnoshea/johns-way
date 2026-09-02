#!/usr/bin/env bash
# Tests for hooks/changed-dependencies.sh.

root=${root:?set by tests/run.sh}

changed() {
    "$root/hooks/changed-dependencies.sh" "$PWD"
}

# Writes a uv.lock with the given package blocks.
write_lock() {
    cat > uv.lock <<'EOF'
version = 1
requires-python = ">=3.13"

[[package]]
name = "myproject"
version = "0.1.0"
source = { editable = "." }
dependencies = [
    { name = "ruff" },
]

[package.metadata]
requires-dist = [{ name = "ruff", specifier = ">=0.12" }]

EOF
    cat >> uv.lock
}

ruff_block() {
    cat <<EOF
[[package]]
name = "ruff"
version = "$1"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/ruff-$1.tar.gz", hash = "sha256:abc", size = 1, upload-time = "$2" }
wheels = [
    { url = "https://files.pythonhosted.org/ruff-$1-py3-none-any.whl", hash = "sha256:def", size = 1, upload-time = "$3" },
]

EOF
}

test_nothing_staged_prints_nothing() {
    make_repo
    assert_eq "" "$(changed)"
}

test_new_lockfile_lists_every_registry_package_with_its_earliest_upload_time() {
    make_repo
    ruff_block 0.12.0 2025-06-17T15:18:45.792Z 2025-06-17T15:10:00.000Z | write_lock
    git add uv.lock
    assert_eq "pypi ruff 0.12.0 2025-06-17T15:10:00.000Z" "$(changed)"
}

test_unchanged_packages_are_not_listed() {
    make_repo
    ruff_block 0.12.0 2025-06-17T15:18:45.792Z 2025-06-17T15:10:00.000Z | write_lock
    git add uv.lock && git commit -q -m "Lock"
    echo "# comment" >> uv.lock
    git add uv.lock
    assert_eq "" "$(changed)"
}

test_changed_version_is_listed() {
    make_repo
    ruff_block 0.12.0 2025-06-17T15:18:45.792Z 2025-06-17T15:10:00.000Z | write_lock
    git add uv.lock && git commit -q -m "Lock"
    ruff_block 0.13.0 2025-09-10T12:00:00.000Z 2025-09-10T12:30:00.000Z | write_lock
    git add uv.lock
    assert_eq "pypi ruff 0.13.0 2025-09-10T12:00:00.000Z" "$(changed)"
}

test_package_without_upload_time_is_listed_as_unknown() {
    make_repo
    write_lock <<'EOF'
[[package]]
name = "old"
version = "1.0.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/old-1.0.0.tar.gz", hash = "sha256:abc", size = 1 }
EOF
    git add uv.lock
    assert_eq "pypi old 1.0.0 unknown" "$(changed)"
}

test_unstaged_lockfile_change_is_ignored() {
    make_repo
    ruff_block 0.12.0 2025-06-17T15:18:45.792Z 2025-06-17T15:10:00.000Z | write_lock
    assert_eq "" "$(changed)"
}

test_added_workflow_actions_are_listed() {
    make_repo
    mkdir -p .github/workflows
    cat > .github/workflows/ci.yml <<'EOF'
jobs:
  test:
    steps:
      - uses: actions/checkout@v5
      - uses: astral-sh/setup-uv@f0ec1fc3b5b9bb3c5b4d67f0e1e8f5f1a1b2c3d4
      - run: echo hi
EOF
    git add .github
    assert_eq "action actions/checkout v5
action astral-sh/setup-uv f0ec1fc3b5b9bb3c5b4d67f0e1e8f5f1a1b2c3d4" "$(changed)"
}

test_unchanged_workflow_lines_are_not_listed() {
    make_repo
    mkdir -p .github/workflows
    printf 'steps:\n  - uses: actions/checkout@v5\n' > .github/workflows/ci.yml
    git add .github && git commit -q -m "CI"
    printf 'steps:\n  - uses: actions/checkout@v5\n  - uses: actions/setup-python@v6\n' > .github/workflows/ci.yml
    git add .github
    assert_eq "action actions/setup-python v6" "$(changed)"
}

test_repo_with_no_commits_yet() {
    git init -q .
    ruff_block 0.12.0 2025-06-17T15:18:45.792Z 2025-06-17T15:10:00.000Z | write_lock
    git add uv.lock
    assert_eq "pypi ruff 0.12.0 2025-06-17T15:10:00.000Z" "$(changed)"
}
