---
name: reviewing-own-work
description: The review at the end of every medium and full task, before the done claim. Dispatches one reviewer with fresh context, relays its findings, and stops at the crit gate. Consult when the last task is committed.
---

# Reviewing own work

One review per task, after the last commit and before saying done.

## Dispatch

Dispatch the `johns-way:reviewer` agent once, with:

- the spec's path, or for medium work the chat design pasted in full
- the base commit: the commit before the first task commit, so that `git diff <base>..HEAD` is the whole change
- the project's check target

The reviewer has fresh context on purpose. Do not summarise the change for it. Give it the spec and the range and let it read.

In Codex, use a fresh subagent with the instructions in `../../agents/reviewer.md` (relative to this skill), omitting its Claude-specific YAML frontmatter. If subagents are unavailable, ask the user to run that review in a new thread; do not claim a fresh-context review happened in the implementation thread.

## Report

Relay the reviewer's findings as they are, grouped by lens: matches the spec, then design rules. Say which findings you disagree with and why. Fix nothing yet.

Print this and stop:

    crit

Where the user's comments and the reviewer's findings disagree, the user's win. Fix what the user asks for, commit, and run the definition of done from routing.
