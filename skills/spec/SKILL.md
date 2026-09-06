---
name: spec
description: Writing the one-page spec for full work after requirements are gathered, including the pushback pass and the crit gate. Consult when the full path reaches the spec, or when the user asks for a spec or design document.
---

# Spec

One file at `docs/specs/YYYY-MM-DD-<topic>.md`, one page unless the approach needs more. No code in it.

## Sections, in order

1. **Problem.** One paragraph: who hits it, what triggers it, what they do today.
2. **Non-goals.** What this change leaves alone.
3. **Approach.** Components and data. Which parts are core, taking data and returning data, and which are shell, performing effects. Apply the design-rules skill.
4. **Alternatives considered.** Rejected options and why. This is the decision record; there are no ADRs.
5. **Open questions.** Carried from requirements. An open question stays open until the user closes it.
6. **Tasks.** A numbered list in build order. Each task is one commit and gives a one-line title and the tests it adds. A task line starts with its number and a period; the SessionStart hook counts those lines to report progress.
7. **Amendments.** Empty at first. Dated entries added during implementation, each giving what changed and why.

Use the terms in CONTEXT.md. A new term the spec needs goes into CONTEXT.md in the same commit; see the domain-language skill.

## Pushback

Before presenting the draft, read it as an adversary and list numbered challenges for the user to accept or reject:

- Contradictions between sections.
- Ambiguity an implementer would have to guess at.
- Scope: anything here that is a separate change. Anything the problem implies that the approach omits.
- Feasibility against the actual code. Read the files the approach touches.
- Tasks that are more than one commit's worth, or whose tests are not stated.

Revise per the user's rulings. A spec with unresolved challenges is not done.

## Gate

Commit the spec. Send a PushNotification, when the host has that tool, saying the spec waits at crit. Print this and stop:

    crit docs/specs/<file>.md

Apply the user's comments as revisions, commit, and print the command again. Repeat until the user says the spec is approved. Implementation starts only then, with the implementing skill.
