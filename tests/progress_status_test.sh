#!/usr/bin/env bash
# Tests for hooks/progress-status.sh.

root=${root:?set by tests/run.sh}

status() {
    "$root/hooks/progress-status.sh" "$PWD"
}

test_outside_a_git_repo_prints_nothing() {
    assert_eq "" "$(status)"
}

test_repo_without_specs_prints_nothing() {
    make_repo
    assert_eq "" "$(status)"
}

test_spec_with_no_tasks_done() {
    make_repo
    make_spec a.md
    assert_eq "Spec docs/specs/a.md: 0 of 3 tasks done. Next: 1. First task. Tests: one." "$(status)"
}

test_spec_with_two_tasks_done() {
    make_repo
    make_spec a.md
    complete_task a.md 1
    complete_task a.md 2
    assert_eq "Spec docs/specs/a.md: 2 of 3 tasks done. Next: 3. Third task. Tests: three." "$(status)"
}

test_next_task_is_the_lowest_not_done() {
    make_repo
    make_spec a.md
    complete_task a.md 1
    complete_task a.md 3
    assert_eq "Spec docs/specs/a.md: 2 of 3 tasks done. Next: 2. Second task. Tests: two." "$(status)"
}

test_finished_spec_prints_nothing() {
    make_repo
    make_spec a.md
    complete_task a.md 1
    complete_task a.md 2
    complete_task a.md 3
    assert_eq "" "$(status)"
}

test_commits_for_another_spec_do_not_count() {
    make_repo
    make_spec a.md
    make_spec b.md
    complete_task b.md 1
    assert_contains "$(status)" "Spec docs/specs/a.md: 0 of 3 tasks done."
    assert_contains "$(status)" "Spec docs/specs/b.md: 1 of 3 tasks done."
}

test_numbered_lines_outside_the_tasks_section_are_ignored() {
    make_repo
    mkdir -p docs/specs
    cat > docs/specs/a.md <<'EOF'
# Spec

## Approach

1. Not a task.
2. Also not a task.

## Tasks

1. Only task.

## Amendments

1. Not a task either.
EOF
    git add docs/specs
    git commit -q -m "Add spec"
    assert_eq "Spec docs/specs/a.md: 0 of 1 tasks done. Next: 1. Only task." "$(status)"
}

test_spec_in_a_repo_with_no_commits_yet() {
    git init -q .
    mkdir -p docs/specs
    printf '## Tasks\n\n1. Only task.\n' > docs/specs/a.md
    assert_eq "Spec docs/specs/a.md: 0 of 1 tasks done. Next: 1. Only task." "$(status)"
}

test_uncommitted_change_to_a_tracked_file_is_reported() {
    make_repo
    echo "changed" >> README.md
    assert_eq "Tracked files with uncommitted changes: 1" "$(status)"
}

test_untracked_files_are_not_reported() {
    make_repo
    echo "new" > new.txt
    assert_eq "" "$(status)"
}

test_runs_from_a_subdirectory_of_the_repo() {
    make_repo
    make_spec a.md
    mkdir sub
    cd sub || return 1
    assert_contains "$(status)" "Spec docs/specs/a.md: 0 of 3 tasks done."
}
