---
name: install-pre-commit
description: Install the johns-way check as this repository's git pre-commit hook, so commits made outside Claude Code run the same tests, lint, and dependency cooldown check.
disable-model-invocation: true
---

Run `johns-way-install-pre-commit` from the repository root and report its output in one line.

If it refuses because another pre-commit hook exists, show that hook's contents and stop. Merging hooks is the user's call.
