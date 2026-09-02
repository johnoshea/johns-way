---
name: pull-requests
description: Creating pull requests with gh. Consult before opening or updating a pull request, and when work on a repository that uses pull requests is ready to share.
---

# Pull requests

Before a pull request is opened, the commit check has passed on every commit and the reviewing-own-work skill has run.

## Description

Written for a reviewer who was not in the session:

1. What changed and why, in a few sentences, with the why first.
2. Alternatives rejected, one line each, when there were any.
3. How to verify: the command to run, and what to look at by hand if anything.
4. Breaking changes, if any.

Link the issue with a closing keyword when the pull request finishes it. No test evidence in the description; the checks show it.

## Size

A diff above roughly 400 changed lines gets a proposal to split before it is opened. One pull request per concern.

## Mechanics

`gh pr create` with the description as the body. Draft when the work is not ready for review. Follow the repository's branch naming and merge conventions; read a recent merged pull request to learn them before opening the first one. Never force-push a branch someone else has commits on.
