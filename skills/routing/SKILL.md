---
name: routing
description: How every request is sized and which path it is put on. Injected into every session by the johns-way SessionStart hook. Consult when unsure which path a request is on, or when work changes size mid-task.
---

# Routing

In Codex, interpret AskUserQuestion as the available question tool, or a direct question followed by waiting when no tool is available. Resolve plugin skills by name from the installed skills list. Resolve `bin/` commands and `agents/reviewer.md` relative to this skill's plugin root (`../..`); Codex need not add `bin/` to PATH. Project judgment rules are in AGENTS.md in Codex and CLAUDE.md in Claude Code.

Classify every request before starting work. If the user names a path, use it as stated. Otherwise pick the smallest path that fits the facts below, announce it in one line, and proceed. The classification has no approval gate. If the session status below includes an unfinished spec or uncommitted changes, mention that in one line before starting.

## Paths

**Small.** The change is inside one module's internals, with no change to an interface another module calls or to a persisted data shape, and fits in one commit. Ask only if the request is ambiguous. The tdd skill, the definition of done, commit. No documents, no review.

**Medium.** The change is to an interface, a second module, or a persisted shape, and the flow being changed already exists in the repo. The requirements skill, one round if needed. Give the design in one chat message: purpose, approach, any new interface in one line, files touched, tests. If the design includes a choice, ask it with AskUserQuestion and wait. Otherwise start. The implementing skill, then reviewing-own-work, then the definition of done. No documents.

**Full.** A new flow, subsystem, or project, or a decision that is expensive to reverse: persistence, concurrency, an external system, authentication, deployment target. The requirements skill, then the spec skill with its crit gate, then the implementing skill one commit per task, then reviewing-own-work, then the definition of done.

**Spike.** The request is a question and the output is an answer rather than code to keep. The spike skill.

Any bug, failing test, or unexpected behaviour: the debugging skill before any fix, on whichever path the fix then takes.

## Changing path

Downgrade whenever the remaining work fits a smaller path: say so in one line and continue. When the user names a smaller path, drop to it at once.

Upgrade only on one of these triggers: the change includes a second module's interface; the change includes a persisted data shape; you find a decision that is expensive to reverse. State the trigger and ask with AskUserQuestion whether to step up. Stay on the current path until the user confirms. A feeling that the work is getting complex is never a trigger.

When you receive the session check-in message during a medium task, stop and ask with AskUserQuestion whether to continue as medium or upgrade to full.

## Subagents

Run implementation in the main context. Use subagents for two jobs only: background fact-finding during requirements, and one review of each medium or full task.

## Definition of done

Before saying done, fixed, or works: run the project's check target, which is `just check` where a justfile exists and otherwise the test and lint commands, and paste the real output. "Should work" means unfinished. Say what was skipped and why. Update README.md, CLAUDE.md, and CONTEXT.md to match what the code now does, in the same commit as the code. Write the commit subject in the imperative, under 72 characters, as a statement of the change to the files. For a rule or prose change, name the file and its new content. Put the rule's own wording in the body. In the body, give the reason whenever it is not visible in the diff. Leave test evidence out of the message. Run the plainly skill on the message before committing. The commit check blocks a sentence over 25 words or a semicolon.
