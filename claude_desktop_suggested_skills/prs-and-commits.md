---
name: prs-and-commits
description: House conventions for commits, branches, and pull requests. Consult before any git commit, branch creation, or PR — including via the gh CLI.
---

# PRs and commits

## Commits
- Format: `[TODO: e.g. conventional commits]`. Subject ≤ 72 chars, imperative mood.
- Body only when the diff doesn't explain itself.
- Never commit without the canon-tdd definition-of-done passing.

## Branches
- Naming: `[TODO: scheme]`

## Pull requests
- Create with: `[TODO: gh pr create flags — draft? base branch?]`
- Description: what/why in 2–4 sentences; test evidence (which tests were added first, red→green); breaking changes if any.
- Link the issue.
- If the diff exceeds ~400 lines, propose a split before opening.
