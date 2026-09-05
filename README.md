# johns-way

A Claude Code plugin that gives Claude one fixed way of working on a codebase. It sizes every request before starting, writes a test before the code, writes a one-page spec before large work, records progress in git, and reviews finished work with fresh eyes. Hooks enforce the mechanical rules: every commit passes the project's checks, no dependency under 14 days old gets in, Python runs through uv, and a decision that belongs to the user is asked rather than announced.

It is built for one person working alone and committing straight to main. It is opinionated. The [design](docs/design.md) says what it does and why.

## Install

Add this repository as a marketplace, then install the plugin from it:

    /plugin marketplace add johnoshea/johns-way
    /plugin install johns-way@johns-way

Skills are then available as `/johns-way:<skill>`, and the routing rules load at the start of every session.

The hooks need `bash`, `git`, and `jq`. The dependency cooldown needs `curl` for PyPI and `gh` for GitHub Actions. Python projects need `uv`, and projects with a justfile need `just`.

## How it works

### Paths

Every request is classified onto a path before work starts. Claude picks the smallest path the facts allow and says which in one line. The user can name a path in the request, or ask for a smaller one at any time.

| Path | When | Process |
| --- | --- | --- |
| Small | The change stays inside one module and fits in one commit | Test first, then commit |
| Medium | An interface, a second module, or a persisted shape changes in a flow that already exists | A design in one chat message, test-first commits, then a review |
| Full | A new flow or subsystem, or a decision that is expensive to reverse | Requirements, a spec with an ordered task list, one commit per task, then a review |
| Spike | The request is a question | Throwaway code on a branch, a one-paragraph answer, and the branch deleted |

Moving to a larger path needs one of three triggers and the user's confirmation: the change reaches a second module's interface, a persisted data shape changes, or a decision that is expensive to reverse appears.

### Specs and progress

On the full path, the spec at `docs/specs/YYYY-MM-DD-<topic>.md` holds the design and a numbered task list. Each task is one commit whose message ends with two trailers:

    Spec: docs/specs/2026-09-02-foo.md
    Task: 3

Git is the progress record, and the spec is never edited to track it. At the start of every session, the plugin reports each spec with unfinished tasks, its next task, and any uncommitted changes.

### Skills

| Skill | When Claude uses it |
| --- | --- |
| routing | Every session, injected at start. Holds the paths and the definition of done |
| requirements | Before designing medium or full work. Rounds of numbered questions, each with a recommended answer |
| spec | Full work. Writes the spec, runs a pushback pass over it, then stops for the user's review |
| tdd | Every code change. The Canon TDD loop |
| implementing | Working a task list. One commit per task, resuming across sessions, amending a spec that turns out wrong |
| debugging | Any bug or failing test. The cause before the fix |
| reviewing-own-work | After the last commit of medium or full work. Dispatches the reviewer agent, then stops for the user's comments |
| design-rules | Shaping an interface or judging a diff for complexity |
| domain-language | Keeping the project's glossary in `CONTEXT.md` |
| spike | Answering a feasibility question with throwaway code |
| issues | Filing and reading GitHub issues |
| pull-requests | Writing a pull request |
| reviewing-prs | Reviewing other people's pull requests |
| dependencies | Adding or updating a dependency, or editing CI |
| review-architecture | On request. A deep design review in the style of A Philosophy of Software Design |
| review-security | On request. A deep security review in the style of Designing Secure Software |
| install-pre-commit | On request. Installs the commit check as the repository's git pre-commit hook |

### Hooks

| Hook | Event | What it does |
| --- | --- | --- |
| session-start | SessionStart | Injects the routing skill, reports unfinished specs and uncommitted changes, records the start time |
| commit-check | PreToolUse on Bash | Before `git commit`: the dependency cooldown, then the project's check target. Blocks `--no-verify` |
| check-in | PostToolUse | Once per session, after the minutes in `JOHNS_WAY_CHECKIN_MINUTES`, 60 by default, asks whether medium work should upgrade |
| enforce-uv | PreToolUse on Bash | Blocks direct python and pip in favour of uv |
| ask-dont-announce | Stop | Blocks a turn that announces a decision and invites an objection, and sends Claude back to ask |

The check target is `just check` where the justfile has a check recipe, otherwise pytest and ruff through uv where there is a pyproject.toml. The cooldown reads the staged `uv.lock` and any `uses:` lines added to workflow files, and blocks a version released under 14 days ago.

Two commands are on the Bash PATH while the plugin is enabled. `johns-way-install-pre-commit` installs the commit check as the current repository's git pre-commit hook, so commits made outside Claude Code get the same check. `johns-way-release-date` prints when a package version or Action ref was released.

## Developing

Clone the repository and link it into the skills directory:

    just install

It then loads as `johns-way@skills-dir` with no install step. A machine that also has the marketplace copy installed keeps only one of the two enabled, or every hook fires twice. `claude plugin disable johns-way@johns-way` turns the marketplace copy off. Edits to a skill apply at once. Edits to hooks need `/reload-plugins` or a new session. `claude --plugin-dir .` loads the checkout for one session without linking.

    just check

Runs shellcheck over the scripts, the plugin validator, and the tests. The tests are plain bash: every function named `test_*` in `tests/*_test.sh` runs in its own temporary directory. The same check runs in GitHub Actions on every push.

Installed copies update only when `version` in `.claude-plugin/plugin.json` changes.

## Layout

```
.claude-plugin/plugin.json        manifest
.claude-plugin/marketplace.json   lists this repository as a one-plugin marketplace
skills/<name>/SKILL.md            one skill per folder
skills/<name>/references/         reference material a review skill loads on demand
hooks/hooks.json                  hook registrations
hooks/*.sh                        hook scripts
agents/reviewer.md                the review subagent
bin/                              executables on the Bash PATH while the plugin is enabled
tests/                            test runner, helpers, and tests
docs/design.md                    the design
CONTEXT.md                        the glossary
```

`claude_desktop_suggested_skills/` holds earlier drafts kept for reference only.
