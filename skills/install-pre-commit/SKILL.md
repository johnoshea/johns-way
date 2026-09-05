---
name: install-pre-commit
description: Only on explicit user request, install the johns-way check as this repository's git pre-commit hook, so commits made outside the agent run the same tests, lint, and dependency cooldown check.
---

Run only when the user explicitly asks to install the pre-commit hook. Run `johns-way-install-pre-commit` from the repository root and report its output in one line.

If it is not on PATH, resolve `../../bin/johns-way-install-pre-commit` relative to this skill's directory and run that absolute path from the project repository root.

If it refuses because another pre-commit hook exists, show that hook's contents and stop. Merging hooks is the user's call.
