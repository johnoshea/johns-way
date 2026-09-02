---
name: routing
description: How every request is sized and which path it takes. Injected into every session by the johns-way SessionStart hook. Consult when unsure which path a request is on, or when work changes size mid-task.
---

# Routing

Classify every request before starting work. If the user names a path, use it as stated. Otherwise pick the smallest path the facts below allow, announce it in one line, and proceed. The classification has no approval gate. If the session status below reports an unfinished spec or uncommitted changes, mention that in one line before starting.

## Paths

**Small.** The change stays inside one module's internals, changes no interface another module calls, changes no persisted data shape, and fits in one commit. Ask only if the request is ambiguous. TDD, definition of done, commit. No documents, no review subagent.

**Medium.** The change touches an interface, a second module, or a persisted shape, and the flow being changed already exists in the repo. Ask one round of questions if needed. Give the design in one chat message: approach, files touched, tests. If the design involves a choice, ask it with AskUserQuestion and wait. Otherwise start. TDD, review, definition of done. No documents.

**Full.** A new flow, subsystem, or project, or a decision that is expensive to reverse: persistence, concurrency, an external system, authentication, deployment target. Requirements rounds, a spec file with a task list, one commit per task, review, definition of done.

**Spike.** The request is a question and the output is an answer rather than code to keep. State the question, a turn budget, and what evidence would answer it. Work on a throwaway branch. End with a written answer of one paragraph. Delete the branch.

## Changing path

Downgrade whenever the remaining work fits a smaller path: say so in one line and continue. When the user names a smaller path, drop to it at once.

Upgrade only on one of these triggers: the change reaches a second module's interface; a persisted data shape changes; a decision that is expensive to reverse appears. State the trigger and ask with AskUserQuestion whether to step up. Stay on the current path until the user confirms. A feeling that the work is getting complex is never a trigger.

When the session check-in message arrives during a medium task, stop and ask with AskUserQuestion whether to continue as medium or upgrade to full.

## Subagents

Implementation runs in the main context. Subagents do two jobs only: fact-finding during requirements, in the background, and one review per medium or full task.

## Definition of done

Before saying done, fixed, or works: run the project's check target, which is `just check` where a justfile exists and otherwise the test and lint commands, and paste the real output. "Should work" means unfinished. Say what was skipped and why.
