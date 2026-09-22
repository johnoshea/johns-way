# johns-way

A Claude Code and Codex plugin that gives the agent one fixed way of working on a codebase. It sizes every request before starting, writes a test before the code, writes a one-page spec before large work, records progress in git, reviews finished work with fresh eyes, and sends every commit message to a reader with no session context before committing. Hooks enforce the mechanical rules: every commit passes the project's checks, every commit message and every reply reads in short sentences, no dependency under 14 days old gets in, Python runs through uv, and a decision that belongs to the user is asked rather than announced.

It is built for one person working alone and committing straight to main. It is opinionated. The [design](docs/design.md) says what it does and why.

## Install

### Claude Code

Add this repository as a marketplace, then install the plugin from it:

    /plugin marketplace add johnoshea/johns-way
    /plugin install johns-way@johns-way

Skills are then available as `/johns-way:<skill>`, and the routing rules load at the start of every session.

The hooks need `bash`, `git`, and `jq`. The dependency cooldown needs `curl` for PyPI and `gh` for GitHub Actions. Python projects need `uv`, and projects with a justfile need `just`.

### Codex

Use a current Codex CLI with `codex plugin` support (tested with 0.153.4). Add this repository as a marketplace and install:

    codex plugin marketplace add johnoshea/johns-way
    codex plugin add johns-way@johns-way

Start a new thread after installation. In the CLI, open `/hooks` and review and trust the plugin hooks; installation alone does not enable their execution. Start another new thread after trusting them so the SessionStart hook loads routing. In the app, ask to use johns-way or choose its skills from the composer. In the CLI, use the skill picker (`$`) to select a bundled skill.

The same skills and hooks serve both hosts. Codex receives routing and progress through SessionStart, checks shell commands through PreToolUse, and reads the final message directly for the Stop checks. Codex uses its own question tools and a fresh general subagent with the bundled reviewer instructions. It does not register the Claude named reviewer profile. If subagents are unavailable, the review needs a separate thread. The skills locate helper commands inside the plugin when `bin/` is not on PATH.

Hook enforcement requires a Codex build and surface that supports plugin hooks, plus explicit hook trust. Skills remain usable without hooks, but routing must then be invoked explicitly and mechanical checks are not automatic. Use the same hook prerequisites listed above; `crit` must also be installed for the spec and review gates.

To update a public installation:

    codex plugin marketplace upgrade johns-way
    codex plugin add johns-way@johns-way

Then start a new thread and review any changed hooks. To uninstall:

    codex plugin remove johns-way@johns-way
    codex plugin marketplace remove johns-way

See the official [plugin packaging](https://developers.openai.com/plugins/build/plugins) and [hook setup](https://learn.chatgpt.com/docs/hooks) documentation.

## How it works

### Paths

Every request is classified onto a path before work starts. The agent picks the smallest path the facts allow and says which in one line. The user can name a path in the request, or ask for a smaller one at any time.

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

| Skill | When the agent uses it |
| --- | --- |
| routing | Every session, injected at start. Holds the paths and the definition of done |
| requirements | Before designing medium or full work. Writes the purpose back for the user to correct, then asks rounds of numbered questions, each with a recommended answer |
| spec | Full work. Designs the approach twice, writes the spec, runs a pushback pass over it, then notifies the user and stops for their review |
| tdd | Every code change. The Canon TDD loop, and the deletion test every test must pass |
| implementing | Working a task list. One commit per task, resuming across sessions, amending a spec that turns out wrong |
| debugging | Any bug or failing test. The cause before the fix |
| reviewing-own-work | After the last commit of medium or full work. Dispatches the reviewer agent, writes its findings to a file for crit, notifies the user, and stops for their comments |
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
| commit-check | PreToolUse on Bash | Before `git commit`: the dependency cooldown, then the project's check target. Blocks `--no-verify`, and a message with a sentence over 25 words or a semicolon |
| check-in | PostToolUse | Once per session, after the minutes in `JOHNS_WAY_CHECKIN_MINUTES`, 60 by default, asks whether medium work should upgrade |
| enforce-uv | PreToolUse on Bash | Blocks direct python and pip in favour of uv |
| ask-dont-announce | Stop | Blocks a turn that announces a decision and invites an objection, and sends Claude back to ask |
| plain-reply | Stop, off | Off: `hooks/hooks.json` leaves it unregistered, so replies keep Claude's own wording. When registered, it blocks a turn whose last message has a sentence over 25 words or a semicolon, or has over 250 words and a first heading other than Summary. Sends Claude back to rewrite it |
| gate | Stop, PreToolUse, PostToolUse, UserPromptSubmit | Holds the session at a crit gate: blocks tool calls until the user's next message, and holds when a background task finishes meanwhile |

The check target is `just check` where the justfile has a check recipe, otherwise pytest and ruff through uv where there is a pyproject.toml. The cooldown reads the staged `uv.lock` and any `uses:` lines added to workflow files, and blocks a version released under 14 days ago.

Two commands are on the Bash PATH while the plugin is enabled. `johns-way-install-pre-commit` installs the commit check as the current repository's git pre-commit hook, so commits made outside Claude Code get the same check. `johns-way-release-date` prints when a package version or Action ref was released.

## Developing

Clone the repository and install the checkout for both Claude Code and Codex:

    just install

For Claude Code, it then loads as `johns-way@skills-dir` with no install step. A machine that also has the marketplace copy installed keeps only one of the two enabled, or every hook fires twice. `claude plugin disable johns-way@johns-way` turns the marketplace copy off. Edits to a skill apply at once. Edits to hooks need `/reload-plugins` or a new session. `claude --plugin-dir .` loads the checkout for one session without linking.

For Codex, `just install` copies the checkout into the ignored `.local/codex/plugins/johns-way/`, registers the generated local marketplace, and installs `johns-way@johns-way-local`. It requires `codex`, `jq`, and `rsync`. Rerun after edits, including deleted skills: each run replaces the generated copy and refreshes the cache version without modifying the tracked release version. Start a new thread after each install and review changed hooks in `/hooks`.

Use `just install-claude` or `just install-codex` to install only one host. If the public Codex copy is also installed, remove it with `codex plugin remove johns-way@johns-way` before using the local copy, to avoid duplicate skills and hooks. To switch back, remove `johns-way@johns-way-local`, remove the `johns-way-local` marketplace, and follow the public instructions above. Keep the checkout in place while using its local marketplace; rerun installation if you move it.

    just check

Runs shellcheck over the scripts, the plugin validator, and the tests. The tests are plain bash: every function named `test_*` in `tests/*_test.sh` runs in its own temporary directory. The same check runs in GitHub Actions on every push.

For releases, bump `version` in both `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`. Installed copies use the version to identify updates; the local Codex install supplies its own cache suffix.

## Layout

```
.codex-plugin/plugin.json         Codex manifest
.agents/plugins/marketplace.json  Codex public marketplace
.claude-plugin/plugin.json        Claude Code manifest
.claude-plugin/marketplace.json   lists this repository as a one-plugin marketplace
skills/<name>/SKILL.md            one skill per folder
skills/<name>/references/         reference material a review skill loads on demand
hooks/hooks.json                  hook registrations
hooks/*.sh                        hook scripts
agents/reviewer.md                the review subagent
bin/                              executables on the Bash PATH while the plugin is enabled
tests/                            test runner, helpers, and tests
docs/design.md                    the design
docs/2026-09-07-ousterhout-review.md  where the plugin holds three ideas from A Philosophy of Software Design
CONTEXT.md                        the glossary
```

`claude_desktop_suggested_skills/` holds earlier drafts kept for reference only.
