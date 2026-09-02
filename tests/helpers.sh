#!/usr/bin/env bash
# Assertion helpers and fixtures shared by tests/*_test.sh.

assert_eq() {
    local expected=$1 actual=$2
    if [ "$expected" != "$actual" ]; then
        echo "expected:"
        printf '%s\n' "$expected"
        echo "actual:"
        printf '%s\n' "$actual"
        return 1
    fi
}

assert_contains() {
    local haystack=$1 needle=$2
    if ! printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "expected to contain: $needle"
        echo "actual:"
        printf '%s\n' "$haystack"
        return 1
    fi
}

assert_not_contains() {
    local haystack=$1 needle=$2
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "expected not to contain: $needle"
        echo "actual:"
        printf '%s\n' "$haystack"
        return 1
    fi
}

# Creates a git repository in the current directory with one commit.
make_repo() {
    git init -q .
    git config user.email test@example.com
    git config user.name Test
    echo "# readme" > README.md
    git add README.md
    git commit -q -m "Initial commit"
}

# Writes a spec with three tasks to docs/specs/$1 and commits it.
make_spec() {
    local name=$1
    mkdir -p docs/specs
    cat > "docs/specs/$name" <<'EOF'
# Spec

## Problem

Something.

## Tasks

1. First task. Tests: one.
2. Second task. Tests: two.
3. Third task. Tests: three.

## Amendments
EOF
    git add docs/specs
    git commit -q -m "Add spec"
}

# Makes an empty commit marking task $2 of spec $1 as done.
complete_task() {
    local spec=$1 task=$2
    git commit -q --allow-empty -m "Do task $task

Spec: docs/specs/$spec
Task: $task"
}
