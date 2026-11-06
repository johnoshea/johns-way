---
name: spec
description: Writing the one-page spec for full work after requirements are gathered, including the pushback pass and the crit gate. Consult at the spec step of the full path, or when the user asks for a spec or design document.
---

# Spec

One file at `docs/specs/YYYY-MM-DD-<topic>.md`, one page unless the approach needs more. No code in it.

## Sections, in order

1. **Problem.** One paragraph: who hits it, what triggers it, what they do today, and how they will tell it is fixed. It contains the purpose agreed in requirements.
2. **Non-goals.** What is out of scope for this change.
3. **Approach.** Components and data. Which parts are core, taking data and returning data, and which are shell, performing effects. For each component, one line with what a caller gives it and gets back. That is its interface, judged for depth here, before any code exists. Apply the design-rules skill.
4. **Alternatives considered.** Rejected options and why. This is the decision record; there are no ADRs.
5. **Open questions.** Carried from requirements. An open question stays open until the user closes it.
6. **Tasks.** A numbered list in build order. Each task is one commit, with a one-line title and the tests added in that commit. A task line starts with its number and a period; the SessionStart hook counts those lines to report progress.
7. **Amendments.** Empty at first. Dated entries added during implementation, each with what changed and why.

Use the terms in CONTEXT.md. Add any new term used in the spec to CONTEXT.md in the same commit; see the domain-language skill.

## Two designs

Before writing Approach, sketch two approaches that differ in where the interfaces fall. Compare them on the design rules: which has the deeper modules, which needs fewer special cases, which is easier to delete. Write the winner as Approach and the loser into Alternatives considered with the reason. If neither design is better on the design rules, the choice is the user's: ask with AskUserQuestion and wait.

## Pushback

Before presenting the draft, read it as an adversary and list numbered challenges for the user to accept or reject:

- Contradictions between sections.
- Ambiguity an implementer would have to guess at.
- Scope: anything here that is a separate change. Any component or task not needed for the Problem paragraph. Anything implied by the problem but missing from the approach.
- Feasibility against the actual code. Read the files changed by the approach.
- Tasks that are more than one commit's worth, or whose tests are not stated.

Revise per the user's rulings. A spec with unresolved challenges is not done.

## Gate

Commit the spec. Send a PushNotification, when the host has that tool, saying the spec is ready for crit. Print this and stop:

    crit docs/specs/<file>.md

Apply the user's comments as revisions, commit, and print the command again. Repeat until the user says the spec is approved. Start implementation only then, with the implementing skill.
