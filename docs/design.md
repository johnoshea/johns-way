# Design: a workflow plugin for Claude Code and Codex

## Purpose

This plugin replaces Superpowers for one person working alone and committing straight to main.

It keeps the parts of Superpowers that earn their time: Canon TDD, systematic debugging, a spec before large work, and a review with fresh eyes. It removes the parts that cost wall-clock time and add ceremony: a fresh subagent per task, a plan document separate from the spec, an approval gate on every path, and a default that escalates when in doubt.

## Principles

- **The lightest path the evidence allows.** Classification uses countable facts. The default is the smaller class. The user can name the path up front or request a downgrade at any time, and neither waits for anything. Upgrading needs one of three named triggers and the user's confirmation.
- **Implementation runs in the main context.** Subagents do two jobs: fact-finding during requirements, and one review per feature.
- **One document per feature.** The spec holds the design and the ordered task list. There is no separate plan.
- **Git is the progress record.** Each task is one commit carrying a trailer that names the spec and the task number. The spec is never edited to track progress.
- **Hooks hold mechanical rules. Skills hold procedures. CLAUDE.md holds judgment rules that apply every turn.** A rule goes in the first of those three that can hold it.
- **Every skill fits in one read.** Each SKILL.md is under 60 lines, and all of them together under 800. A skill that runs a periodic audit may carry reference files under `references/`, loaded on demand and outside the budget.

## Paths

Every request is classified before work starts. If the user names a path in the request, that path is used as stated. Otherwise the model classifies, announces the path in one line, and proceeds. The classification itself has no approval gate. Each path carries its own gate at the point where a real choice exists.

### Small

Criteria: the change stays inside one module's internals. No interface that another module calls changes. No persisted data shape changes. The whole change fits in one commit.

Process: ask only if the request is ambiguous. TDD. Definition of done. Commit.

Documents: none. Review subagent: none.

### Medium

Criteria: the change touches an interface, a second module, or a persisted shape, and the flow being changed already exists in the repo.

Process: one round of questions, usually. The design is one chat message: approach, any new interface in one line, files touched, tests. If the design involves a choice, ask it with AskUserQuestion and wait. With one obvious approach, implementation starts. TDD. Review. Definition of done.

Documents: none. There is no limit on commits. After a configurable time on the session, the session check-in hook has the model ask whether to continue as medium or upgrade to full; see [Hooks](#hooks). If a medium task is interrupted before its last commit, the next session starts by writing the chat design into a spec file and continues on the full path. The SessionStart hook reports uncommitted changes, so an interrupted task is visible.

### Full

Criteria: a new flow, subsystem, or project. Or any decision that is expensive to reverse: persistence, concurrency, an external system, authentication, deployment target.

Process: requirements rounds. Two approaches compared on the design rules, the loser recorded under Alternatives considered. A spec file with an ordered task list. A pushback pass. The `crit` gate on the spec. Implementation task by task, one commit each. Review. Definition of done.

Documents: one spec file.

### Spike

Criteria: the request is a question, and the output is an answer rather than code to keep.

Process: see [Spikes](#spikes).

### Downgrade and upgrade

Downgrade: at any point, if the remaining work fits a smaller class, say so in one line and continue on the smaller path. The user can request a downgrade at any time by naming the smaller path. The model drops to it at once, without asking.

Upgrade triggers, and only these:

1. The change reaches a second module's interface.
2. A persisted data shape changes.
3. A decision that is expensive to reverse appears.

When a trigger appears, state it and ask with AskUserQuestion whether to step up. The work stays on the current path until the user confirms. A feeling that the work is getting complex is never a trigger.

## Skills

Each entry gives the trigger, what the skill does, and what it produces.

**routing.** Always loaded, injected by the SessionStart hook. Holds the path criteria, the downgrade and upgrade rules, the response to the session check-in, the subagent policy, and the definition of done. Definition of done: run the project's check target, paste the real output, and treat "should work" as unfinished. Under 40 lines.

**requirements.** Medium and full paths. Asks rounds of numbered questions, each with a recommended answer as a starting point. The user answers in whatever depth the decision needs. Asks everything askable now in one round. Asks only about decisions that are expensive to reverse; everything else gets a stated default. Facts are looked up, never asked, and lookups run as background subagents so no question waits on one. Opens with countable questions: kinds of user, external systems, things that persist, things that happen without a user asking. A round that settles nothing gets two drafts for the user to compare instead. Stops when answers stop changing the design. After three rounds, lists the questions still open and waits. The user answers them, or says to draft with them left open.

**spec.** Full path. Sketches two approaches that differ in where the interfaces fall, compares them on the design rules, and writes the loser into Alternatives considered. Writes the spec in the format under [Spec format](#spec-format). Runs the pushback pass before presenting: contradictions between sections, ambiguity an implementer would have to guess at, scope that belongs in a separate change, feasibility against the actual code. Ends by sending a push notification, printing `crit docs/specs/<file>.md`, and stopping.

**tdd.** Every code change. The Canon TDD loop: write the test list, pick one test, watch it fail, write the minimum code, refactor as a separate step, repeat. A test that expects an error prompts the question whether the contract could make that case normal. Scaled to the change: a tiny fix gets one test. A bug fix starts with the failing test that reproduces it.

**implementing.** Medium and full paths. Works the task list in order. One task is one commit, with the trailers under [Progress tracking](#progress-tracking). The refactor step asks the questions under [Design rules](#design-rules). Updates CONTEXT.md, README.md, and CLAUDE.md in the same commit as the code that changes them. On resume: read the status the SessionStart hook printed, confirm the next task in one line, continue. When implementation shows the spec is wrong: stop, state what is wrong and the proposed amendment, and ask with AskUserQuestion. On approval, add the entry to the spec's Amendments section, commit that change, and continue.

**debugging.** Any bug, failing test, error, or unexpected behaviour. Read the whole error. Reproduce it. Check what changed. Find the cheapest test that settles the question before adding instrumentation. One hypothesis at a time, stated before touching code. Failing test, then the fix. Three failed fixes means a design problem: stop and discuss. Done only when the cause can be stated in a sentence.

**reviewing-own-work.** End of every medium and full task, before the done claim. Dispatches the plugin's reviewer agent, defined under `agents/`, once with fresh context. Inputs: the spec, or the chat design pasted in, and the diff since the first task commit. Two lenses: the code matches the spec, and the code passes the [Design rules](#design-rules). Writes the findings to a file outside the repository, sends a push notification, prints `crit <file>`, and stops.

**reviewing-prs.** Other people's pull requests. Reads the linked issue and the description for intent. Reviews the diff for correctness first, then design. Posts comments with `gh`. Approves or requests changes only when asked to.

**review-architecture.** User-invoked. A deep, periodic design review in the style of Ousterhout's A Philosophy of Software Design, judged by the complexity it adds. Maps the modules and their dependencies before judging anything, weighs deep versus shallow modules and information leakage above all, designs the top finding twice, and reports a verdict, the structural issues that matter, lesser findings, what is good, and one next step. Its detection catalogue and worked examples live under `references/`. Runs in the main context: a session opened for the review is already fresh.

**review-security.** User-invoked. A deep, periodic security review with fresh eyes, following Kohnfelder's Designing Secure Software and the Saltzer and Schroeder principles, with the CWE Top 25 and the OWASP Top 10 as its catalogue. Lists assets, attack surface, and trust boundaries before judging any line, works inward from the most exposed surface to the most valuable asset, and reports weaknesses marked Must, Ought, or Should, ranked by what an attacker gains and how reachable it is. Same layout and context as review-architecture.

**pull-requests.** Creating pull requests. Description: what and why in a few sentences, alternatives rejected, how to verify. Links the issue. Proposes a split above roughly 400 changed lines.

**issues.** Filing, reading, and updating GitHub issues. An issue is the input to requirements when one exists. Issues hold deferred work: found while working, out of scope, or blocked. The spec's task list holds work being done now. Work is in one place or the other, never both. Feature issues carry acceptance criteria written as a test list.

**spike.** See [Spikes](#spikes).

**domain-language.** Whenever a term is discussed, a class or function with domain meaning is added, or CONTEXT.md is edited. Adapted from Matt Pocock's domain-modeling skill. See [Domain language](#domain-language).

**design-rules.** Shaping an interface, adding an abstraction, parameter, or branch, or judging a diff for complexity. Holds the rules under [Design rules](#design-rules) in one place, applied by spec, implementing, and reviewing-own-work.

**install-pre-commit.** User-invoked. Runs the installer in `bin/` that writes the repository pre-commit hook.

**dependencies.** Adding or updating a dependency, or editing CI. Takes the newest version that clears the 14-day cooldown, looking release dates up with `johns-way-release-date` from `bin/`. Uses the latest Python release that clears it. Updates every GitHub Action when touching CI, looking each version up. Keeps the CI Python version equal to the one in pyproject.toml in the same commit.

## Hooks

**SessionStart.** Matcher `startup|resume|clear|compact|fork`. Prints the routing skill in full. Then prints progress status: for each spec under `docs/specs/`, the task count and the completed count, and the next task for any unfinished spec. Then prints a one-line summary of uncommitted changes to tracked files, when there are any. Records the session's start time for the check-in hook.

**Session check-in.** A PostToolUse hook on every tool compares the time since the session started with a limit. The limit comes from the `JOHNS_WAY_CHECKIN_MINUTES` environment variable and is 60 by default. The first time the limit is passed, the hook delivers one message to the model: if a medium task is in progress, stop and ask with AskUserQuestion whether to continue as medium or upgrade to full. It fires once per session. Start times live under the plugin's data directory, keyed by session id. Compaction continues the same sitting and keeps the clock; startup, resume, clear, and fork restart it. Delivery uses the hook's `additionalContext` output, which PostToolUse supports.

**Commit check.** PreToolUse on Bash when the command runs `git commit`. Runs the cooldown check, then `just check` when the justfile has a check recipe, otherwise pytest and ruff through uv when there is a pyproject.toml. Blocks the commit with exit code 2 on failure, printing the output. A commit with `--no-verify` is blocked outright. When the repository's own pre-commit hook is ours, git runs the same check, so this hook steps aside rather than run it twice.

**Cooldown check.** Reads the staged `uv.lock`. Every registry package whose name and version pair is new is checked against the upload time uv records for its files, with no network. A package without one is looked up on PyPI. For each `uses:` line added under `.github/workflows/`, the date of the commit the ref points at is fetched through `gh api`. Blocks if any is under 14 days old. A version whose date cannot be found blocks too.

**Repo pre-commit hook.** `johns-way-install-pre-commit`, on the Bash PATH while the plugin is enabled, installs the same check script as the git pre-commit hook of the current repo, so manual commits get the same protection. Both hooks call one script. The installed hook finds the current copy of the plugin at commit time: the development link in the skills directory, else the newest version in the plugin cache, else the copy it was installed from. A cached version is removed some time after an update, so its path is never fixed into the hook. The install-pre-commit skill runs it.

**enforce-uv.** PreToolUse on Bash. Blocks direct python, python3, and pip invocations in favour of uv.

**ask-dont-announce.** Stop. Blocks a turn whose last message announces a decision and invites an objection, and sends the model back to ask with AskUserQuestion.

Both were hooks in settings.json before the plugin existed and moved into it, with their settings.json entries removed in the same change so that only one copy fires. The process-downshift hook that also lived there was removed; the routing rules make it unnecessary. The sidekick hooks are unrelated and stay in settings.json.

**gate.** One script on Stop, PreToolUse, PostToolUse, and UserPromptSubmit, with one state file per session under the plugin's data directory. Stop opens the gate when the last message prints the crit command on a line of its own. PreToolUse blocks every tool call except AskUserQuestion while the gate is open, telling the model to reply in one line and print the command again. UserPromptSubmit closes the gate on the user's next prompt. A background task that finishes arrives as a prompt too, so a task notice keeps the gate and adds context telling the model to hold. PostToolUse on a background `crit` run records the run's task id; until that run's own notice arrives, only reads of that task's output file pass, and a printed crit command leaves the record alone. Startup, resume, clear, and fork remove the file; compaction keeps it. Codex supplies the same four events and the same `prompt` field. The model's own knowledge of the gate is not enough: a task notice reads as a prompt, and the model works on it.

**No Stop hook for uncommitted changes.** A Stop hook could block the model from ending its turn while tracked files have uncommitted changes. That one is left out. The commit check already guarantees every commit passes tests, and the model stops legitimately in that state when it asks about a spec amendment or after a failed fix.

## Spec format

Location: `docs/specs/YYYY-MM-DD-<topic>.md`. Committed before the first task starts.

Sections, in order:

1. **Problem.** One paragraph.
2. **Non-goals.**
3. **Approach.** Components and data, and which parts are core and which are shell. Core takes data and returns data. Shell performs effects. Each component's interface in one line: what a caller gives it and gets back. No code.
4. **Alternatives considered.** Rejected options and why, always including the losing approach. This is the decision record.
5. **Open questions.**
6. **Tasks.** A numbered list. Each task is one commit and gives a one-line title and the tests it adds. A task line starts with its number and a period. The SessionStart hook counts only such lines under this heading.
7. **Amendments.** Empty at first. Dated entries, each giving what changed and why.

One page unless the approach needs more.

## Progress tracking

Every commit that completes a task carries two trailers:

```
Spec: docs/specs/2026-09-02-foo.md
Task: 3
```

The SessionStart hook computes status by counting tasks in each spec file and counting distinct Task values in:

```
git log --format='%(trailers:key=Task,valueonly)' --grep='^Spec: docs/specs/2026-09-02-foo.md$'
```

Rules:

- The spec is edited only to add an amendment.
- A spec is done when every task has a commit.
- An abandoned spec is deleted in a commit whose message says why. Git history keeps it. The hook only reads files that exist.

## Spikes

A spike answers a question. Rules:

- Before starting, state the question, a turn budget, and what evidence would answer it.
- Work on a throwaway branch or worktree. No TDD, no review.
- End with a written answer of one paragraph, in chat, and in the spec's Alternatives or Open questions section if a spec exists.
- Delete the branch. Real implementation starts from main, test-first. It may read the spike before deletion. It never merges it.
- A spike with no answer at the end of its budget is reported as a failed spike.

## Domain language

`CONTEXT.md` at the repo root is the glossary and only the glossary. It is created when the first term needs recording. Each term has a name, a one-sentence definition, and the words to avoid in its place. It is updated in the same commit as the code that introduces a concept.

During requirements and spec writing, terms the user uses are checked against it, and conflicts are raised at once. Decisions are recorded in the spec's Alternatives section. There are no ADRs.

## Design rules

These rules live in the design-rules skill. The spec's Approach section, the implementing skill's refactor step, and the review's second lens all apply them.

- Each module is deep: a caller must know much less than the module hides. A function shorter than the words needed to describe it is collapsed.
- Complexity goes down, not out. A simpler interface beats a simpler implementation.
- A reviewer can follow the diff without reading the rest of the module, or the diff carries a comment saying why.
- Remove a parameter, option, or branch. If nobody would notice, it goes.
- A patch around a design problem is replaced by fixing the interface, or by an issue when that is out of scope.
- Before a try/except or null check, change the interface so the error cannot happen: make the case normal, return a total result, or handle it once low in the module. A real failure still surfaces.
- One adapter is a hypothetical seam. Two adapters is a real one.
- The deletion test: delete the module. If complexity vanishes, it was a pass-through.
- Functional core, imperative shell: pure logic takes data and returns data. Effects live at the edges.
- Strategic DDD only. The ubiquitous language lives in CONTEXT.md and contexts are module boundaries. Aggregates, repositories, and domain events are out unless a spec argues for them.

## CLAUDE.md after migration

Stays in CLAUDE.md: the opening four lines, Working together, Writing style, Human review gates, Toolchain. The gates change target: `crit docs/specs/<file>.md` after the spec, `crit <findings file>` after review.

Moves out:

| CLAUDE.md section | Destination |
| --- | --- |
| Run the full suite before each commit | commit hook |
| Design philosophy | implementing, reviewing-own-work |
| Testing | tdd |
| Domain language | domain-language |
| Dependencies and CI | cooldown hook, dependencies |
| Commit straight to main; feature flags over long branches | implementing |
| Keep README.md and CLAUDE.md up to date | implementing |
| Never work around the cooldown | removed; the hook enforces it |

Stays under Non-negotiables: never invent technical details, never commit secrets, never gut a module without asking, never close an issue or record a decision without being told.

## Packaging

This repository is the plugin. Layout:

```
.claude-plugin/plugin.json
.claude-plugin/marketplace.json lists this repository as a one-plugin marketplace
.github/workflows/check.yml   runs just check on every push
skills/<name>/SKILL.md
skills/<name>/references/*.md reference material a review skill loads on demand
hooks/hooks.json
hooks/*.sh
agents/<name>.md              subagent definitions, referenced as johns-way:<name>
bin/                          executables on the Bash PATH while the plugin is enabled
tests/
docs/
CONTEXT.md                    the glossary
```

The plugin is named `johns-way`. Renaming later means changing the name field in plugin.json and marketplace.json and the symlink directory.

The repository is its own marketplace: marketplace.json lists the one plugin with its source at the repository root. Adding the repository as a marketplace and installing `johns-way@johns-way` from it puts a copy under Claude Code's plugin cache. That copy updates only when the version in plugin.json changes.

For development, `just install` symlinks the repository into `~/.claude/skills/johns-way/`, which Claude Code loads as `johns-way@skills-dir` without an install step. Only one of the two copies is enabled at a time, or every hook fires twice. `claude --plugin-dir .` tests changes. Skills are namespaced `/johns-way:<skill>`.

### Codex packaging

The repository also exposes `.codex-plugin/plugin.json` and a Codex marketplace at `.agents/plugins/marketplace.json`, with the plugin source at the repository root. This keeps skills, helpers, and default `hooks/hooks.json` shared. Codex provides the compatibility plugin environment variables and canonical Bash hook input. The Stop hook prefers the supplied `last_assistant_message`; Claude transcripts remain the fallback when that field is absent.

`just install` installs both hosts; `just install-claude` and `just install-codex` select one. The Codex installer refreshes a generated snapshot under `.local/codex/plugins/johns-way`, adds a cache suffix to its version, registers `johns-way-local` through the CLI, and reinstalls. The tracked version remains a release version. Deleted source files disappear on reinstall. The public and local copies should not both be enabled.

Codex requires a new thread after installation and user trust of hook definitions. Routing maps question tools and helper paths to the host, and the reviewing-own-work skill uses a fresh general subagent with the reviewer instructions. Without subagent support, review runs in a separate thread. The pre-commit skill remains explicitly user-requested, with Codex's `allow_implicit_invocation: false` policy.

## Build order

Each step is usable on its own before the next starts.

1. routing and the SessionStart hook.
2. tdd, implementing, the commit hook, and the session check-in hook with its start-time recording.
3. requirements and spec.
4. reviewing-own-work.
5. debugging, spike, domain-language.
6. issues, pull-requests, reviewing-prs, dependencies.
7. CLAUDE.md migration, moving enforce-uv and ask-dont-announce into the plugin, and removal of process-downshift.

## Deferred

Revisit once the plugin has proven its worth:

- Cooldown checks for Docker images and for the JavaScript ecosystem. Each needs its own registry query.
