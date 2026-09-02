# Design: a workflow plugin for Claude Code

## Purpose

This plugin replaces Superpowers for one person working alone and committing straight to main.

It keeps the parts of Superpowers that earn their time: Canon TDD, systematic debugging, a spec before large work, and a review with fresh eyes. It removes the parts that cost wall-clock time and add ceremony: a fresh subagent per task, a plan document separate from the spec, an approval gate on every path, and a default that escalates when in doubt.

## Principles

- **The lightest path the evidence allows.** Classification uses countable facts. The default is the smaller class. The user can name the path up front or request a downgrade at any time, and neither waits for anything. Upgrading needs one of three named triggers and the user's confirmation.
- **Implementation runs in the main context.** Subagents do two jobs: fact-finding during requirements, and one review per feature.
- **One document per feature.** The spec holds the design and the ordered task list. There is no separate plan.
- **Git is the progress record.** Each task is one commit carrying a trailer that names the spec and the task number. The spec is never edited to track progress.
- **Hooks hold mechanical rules. Skills hold procedures. CLAUDE.md holds judgment rules that apply every turn.** A rule goes in the first of those three that can hold it.
- **Every skill fits in one read.** Under 60 lines each. Under 800 lines in total.

## Paths

Every request is classified before work starts. If the user names a path in the request, that path is used as stated. Otherwise the model classifies, announces the path in one line, and proceeds. The classification itself has no approval gate. Each path carries its own gate at the point where a real choice exists.

### Small

Criteria: the change stays inside one module's internals. No interface that another module calls changes. No persisted data shape changes. The whole change fits in one commit.

Process: ask only if the request is ambiguous. TDD. Definition of done. Commit.

Documents: none. Review subagent: none.

### Medium

Criteria: the change touches an interface, a second module, or a persisted shape, and the flow being changed already exists in the repo.

Process: one round of questions, usually. The design is one chat message: approach, files touched, tests. If the design involves a choice, ask it with AskUserQuestion and wait. With one obvious approach, implementation starts. TDD. Review. Definition of done.

Documents: none. There is no limit on commits. After a configurable time on the session, the session check-in hook has the model ask whether to continue as medium or upgrade to full; see [Hooks](#hooks). If a medium task is interrupted before its last commit, the next session starts by writing the chat design into a spec file and continues on the full path. The SessionStart hook reports uncommitted changes, so an interrupted task is visible.

### Full

Criteria: a new flow, subsystem, or project. Or any decision that is expensive to reverse: persistence, concurrency, an external system, authentication, deployment target.

Process: requirements rounds. A spec file with an ordered task list. A pushback pass. The `crit` gate on the spec. Implementation task by task, one commit each. Review. Definition of done.

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

**requirements.** Medium and full paths. Asks rounds of numbered questions, each with a recommended answer as a starting point. The user answers in whatever depth the decision needs. Asks everything askable now in one round. Asks only about decisions that are expensive to reverse; everything else gets a stated default. Facts are looked up, never asked, and lookups run as background subagents so no question waits on one. Opens with countable questions: kinds of user, external systems, things that persist, things that happen without a user asking. Stops when answers stop changing the design. After three rounds, lists the questions still open and waits. The user answers them, or says to draft with them left open.

**spec.** Full path. Writes the spec in the format under [Spec format](#spec-format). Runs the pushback pass before presenting: contradictions between sections, ambiguity an implementer would have to guess at, scope that belongs in a separate change, feasibility against the actual code. Ends by printing `crit docs/specs/<file>.md` and stopping.

**tdd.** Every code change. The Canon TDD loop: write the test list, pick one test, watch it fail, write the minimum code, refactor as a separate step, repeat. Scaled to the change: a tiny fix gets one test. A bug fix starts with the failing test that reproduces it.

**implementing.** Medium and full paths. Works the task list in order. One task is one commit, with the trailers under [Progress tracking](#progress-tracking). The refactor step asks the questions under [Design rules](#design-rules). Updates CONTEXT.md, README.md, and CLAUDE.md in the same commit as the code that changes them. On resume: read the status the SessionStart hook printed, confirm the next task in one line, continue. When implementation shows the spec is wrong: stop, state what is wrong and the proposed amendment, and ask with AskUserQuestion. On approval, add the entry to the spec's Amendments section, commit that change, and continue.

**debugging.** Any bug, failing test, error, or unexpected behaviour. Read the whole error. Reproduce it. Check what changed. Find the cheapest test that settles the question before adding instrumentation. One hypothesis at a time, stated before touching code. Failing test, then the fix. Three failed fixes means a design problem: stop and discuss. Done only when the cause can be stated in a sentence.

**reviewing-own-work.** End of every medium and full task, before the done claim. Dispatches one subagent with fresh context. Inputs: the spec, or the chat design pasted in, and the diff since the first task commit. Two lenses: the code matches the spec, and the code passes the [Design rules](#design-rules). Reports findings, prints `crit`, and stops.

**reviewing-prs.** Other people's pull requests. Reads the linked issue and the description for intent. Reviews the diff for correctness first, then design. Posts comments with `gh`. Approves or requests changes only when asked to.

**pull-requests.** Creating pull requests. Description: what and why in a few sentences, alternatives rejected, how to verify. Links the issue. Proposes a split above roughly 400 changed lines.

**issues.** Filing, reading, and updating GitHub issues. An issue is the input to requirements when one exists. Issues hold deferred work: found while working, out of scope, or blocked. The spec's task list holds work being done now. Work is in one place or the other, never both. Feature issues carry acceptance criteria written as a test list.

**spike.** See [Spikes](#spikes).

**domain-language.** Whenever a term is discussed, a class or function with domain meaning is added, or CONTEXT.md is edited. Adapted from Matt Pocock's domain-modeling skill. See [Domain language](#domain-language).

**dependencies.** Adding or updating a dependency, or editing CI. Takes the newest version that clears the 14-day cooldown. Uses the latest Python release that clears it. Updates every GitHub Action when touching CI, looking each version up. Keeps the CI Python version equal to the one in pyproject.toml in the same commit.

## Hooks

**SessionStart.** Matcher `startup|resume|clear|compact|fork`. Prints the routing skill in full. Then prints progress status: for each spec under `docs/specs/`, the task count and the completed count, and the next task for any unfinished spec. Then prints a one-line summary of uncommitted changes to tracked files, when there are any. Records the session's start time for the check-in hook.

**Session check-in.** A PostToolUse hook on every tool compares the time since the session started with a limit. The limit comes from the `JOHNS_WAY_CHECKIN_MINUTES` environment variable and is 60 by default. The first time the limit is passed, the hook delivers one message to the model: if a medium task is in progress, stop and ask with AskUserQuestion whether to continue as medium or upgrade to full. It fires once per session. Start times live under the plugin's data directory, keyed by session id. Delivery uses the hook's `additionalContext` output, which PostToolUse supports.

**Commit check.** PreToolUse on Bash when the command contains `git commit`. Runs `just check` if a justfile exists, otherwise the language's test and lint commands. Blocks the commit with exit code 2 on failure, printing the output. Then runs the cooldown check on the staged lockfile diff.

**Cooldown check.** Reads the staged diff of `uv.lock`. For each package whose version changed, fetches the release date from PyPI. For each GitHub Action version changed under `.github/workflows/`, fetches the tag's commit date through `gh api`. Blocks if any is under 14 days old. Fails closed when offline.

**Repo pre-commit hook.** A command installs the same check script as a git pre-commit hook in the current repo, so manual commits get the same protection. Both hooks call one script.

**Existing hooks.** enforce-uv and ask-dont-announce move into the plugin, and their settings.json entries are removed in the same change so that only one copy fires. process-downshift is removed; the routing rules make it unnecessary. The sidekick hooks are unrelated and stay in settings.json.

**No Stop hook.** A Stop hook could block the model from ending its turn while tracked files have uncommitted changes. It is left out. The commit check already guarantees every commit passes tests, and the model stops legitimately in that state when it asks about a spec amendment or after a failed fix.

## Spec format

Location: `docs/specs/YYYY-MM-DD-<topic>.md`. Committed before the first task starts.

Sections, in order:

1. **Problem.** One paragraph.
2. **Non-goals.**
3. **Approach.** Components and data, and which parts are core and which are shell. Core takes data and returns data. Shell performs effects. No code.
4. **Alternatives considered.** Rejected options and why. This is the decision record.
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

These rules live in three places: the spec's Approach section, the implementing skill's refactor step, and the review's second lens.

- Each abstraction earns its keep. A function shorter than the words needed to describe it is collapsed.
- A reviewer can follow the diff without reading the rest of the module, or the diff carries a comment saying why.
- Remove a parameter, option, or branch. If nobody would notice, it goes.
- A patch around a design problem is replaced by fixing the interface, or by an issue when that is out of scope.
- Before a try/except or null check, change the interface so the error cannot happen.
- One adapter is a hypothetical seam. Two adapters is a real one.
- The deletion test: delete the module. If complexity vanishes, it was a pass-through.
- Functional core, imperative shell: pure logic takes data and returns data. Effects live at the edges.
- Strategic DDD only. The ubiquitous language lives in CONTEXT.md and contexts are module boundaries. Aggregates, repositories, and domain events are out unless a spec argues for them.

## CLAUDE.md after migration

Stays in CLAUDE.md: the opening four lines, Working together, Writing style, Human review gates, Toolchain. The gates change target: `crit docs/specs/<file>.md` after the spec, `crit` after review.

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
skills/<name>/SKILL.md
hooks/hooks.json
hooks/*.sh
docs/
```

The plugin is named `johns-way`. Renaming later means changing the name field in plugin.json and the symlink directory.

It loads by symlinking the repository into `~/.claude/skills/johns-way/`, which Claude Code picks up without an install step. `claude --plugin-dir .` tests changes. Skills are namespaced `/johns-way:<skill>`.

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
