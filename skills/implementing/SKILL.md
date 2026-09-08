---
name: implementing
description: How medium and full work gets built once its design or spec exists. One commit per task, git trailers as the progress record, resuming across sessions, and what to do when the spec turns out wrong. Consult when starting or resuming implementation.
---

# Implementing

Work in the main context. Use the tdd skill for every change and the design-rules skill in every refactor step.

## Full path: the spec's task list

The spec is committed before the first task. Work the tasks in its Tasks section in order. One task is one commit. Nothing in the spec is edited to track progress; the commits are the record.

Each task's commit carries two trailers, which the SessionStart hook reads to compute progress:

    Spec: docs/specs/<file>.md
    Task: <number>

## Medium path: the chat design

Commit each coherent piece as soon as it is green, with no trailers. When the session check-in arrives, stop and ask with AskUserQuestion whether to continue as medium or upgrade to full. If a medium task is interrupted before its last commit, the next session writes the chat design into a spec and continues on the full path.

## Every commit

- The commit check hook runs the dependency cooldown and the project's check target. A failing check is fixed, never skipped.
- Update README.md, CLAUDE.md, and CONTEXT.md in the same commit as the code that changes what they describe. A new domain term goes into CONTEXT.md in the commit that introduces it; see the domain-language skill.
- Commit straight to main. Work too big for one releasable commit goes behind a feature flag, never on a long-lived branch.

## Resuming

The SessionStart hook prints any spec with unfinished tasks, its next task, and any uncommitted changes. Confirm the next task in one line and continue. Uncommitted changes from a previous session are read, never discarded: work out which task they belong to, finish it, and commit.

## When the spec is wrong

Implementation sometimes shows that an approach, a task, or an assumption in the spec is wrong. Stop. State what is wrong and the proposed amendment, and ask with AskUserQuestion. On approval, add a dated entry to the spec's Amendments section giving what changed and why, commit that change on its own, and continue. The spec never changes silently.

## Finishing

After the last task: the reviewing-own-work skill, then the definition of done from routing.
