---
name: routing
description: How every request is sized and which path it takes. Injected into every session by the johns-way SessionStart hook. Consult when unsure which path a request is on, or when work changes size mid-task.
---

# Routing

In Codex, interpret AskUserQuestion as the available question tool, or a direct question followed by waiting when no tool is available. Resolve plugin skills by name from the installed skills list. Resolve `bin/` commands and `agents/reviewer.md` relative to this skill's plugin root (`../..`); Codex need not add `bin/` to PATH. Project judgment rules live in AGENTS.md in Codex and CLAUDE.md in Claude Code.

Classify every request before starting work. If the user names a path, use it as stated. Otherwise pick the smallest path the facts below allow, announce it in one line, and proceed. The classification has no approval gate. If the session status below reports an unfinished spec or uncommitted changes, mention that in one line before starting.

## Paths

**Small.** The change stays inside one module's internals, changes no interface another module calls, changes no persisted data shape, and fits in one commit. Ask only if the request is ambiguous. The tdd skill, the definition of done, commit. No documents, no review.

**Medium.** The change touches an interface, a second module, or a persisted shape, and the flow being changed already exists in the repo. The requirements skill, one round if needed. Give the design in one chat message: approach, any new interface in one line, files touched, tests. If the design involves a choice, ask it with AskUserQuestion and wait. Otherwise start. The implementing skill, then reviewing-own-work, then the definition of done. No documents.

**Full.** A new flow, subsystem, or project, or a decision that is expensive to reverse: persistence, concurrency, an external system, authentication, deployment target. The requirements skill, then the spec skill with its crit gate, then the implementing skill one commit per task, then reviewing-own-work, then the definition of done.

**Spike.** The request is a question and the output is an answer rather than code to keep. The spike skill.

Any bug, failing test, or unexpected behaviour: the debugging skill before any fix, on whichever path the fix then takes.

## Changing path

Downgrade whenever the remaining work fits a smaller path: say so in one line and continue. When the user names a smaller path, drop to it at once.

Upgrade only on one of these triggers: the change reaches a second module's interface; a persisted data shape changes; a decision that is expensive to reverse appears. State the trigger and ask with AskUserQuestion whether to step up. Stay on the current path until the user confirms. A feeling that the work is getting complex is never a trigger.

When the session check-in message arrives during a medium task, stop and ask with AskUserQuestion whether to continue as medium or upgrade to full.

## Subagents

Implementation runs in the main context. Subagents do two jobs only: fact-finding during requirements, in the background, and the one review per medium or full task.

## Definition of done

Before saying done, fixed, or works: run the project's check target, which is `just check` where a justfile exists and otherwise the test and lint commands, and paste the real output. "Should work" means unfinished. Say what was skipped and why. README.md, CLAUDE.md, and CONTEXT.md say what the code now does, updated in the same commit as the code. A commit subject is imperative, under 72 characters, and says what the change does to the files. For a rule or prose change, it names the file and what it now says. The rule's own wording goes in the body. The body gives the why whenever the diff does not show it. Test evidence stays out of the message.
