---
name: writing-specs
description: Interrogate-first spec writing. Consult BEFORE writing any code or drafting any document whenever the user asks for a spec, design doc, or feature proposal — or describes a feature idea loosely, even without the word "spec". Never draft a spec as a first response to a loose idea.
---

# Writing specs

A spec is the output of an interrogation, not a first response. Write no code during any phase of this skill.

## Phase 1 — Interrogate

Ask questions until the problem space is sharp. Rules:

- Batch 2–4 questions at a time. Highest-leverage first: prefer questions whose answers would *change the design* over questions that fill in detail.
- Stop when answers stop changing the shape of the spec. Do not interrogate for completeness's sake.
- Never invent an answer the user didn't give. Unknowns become "Open questions" in the draft — not guesses.

Cover, as relevant:
- Who hits this problem, and what triggers it? What do they do today?
- What existing code/behaviour does this touch? (Read it before asking further.)
- Scope: what's explicitly out (non-goals)?
- Edge cases: empty states, failure modes, concurrency, scale.
- Constraints: compatibility, data migration, performance.
- What does "done" look like, observably?

## Phase 2 — Draft

1. **Problem** — one paragraph
2. **Non-goals**
3. **Approach** — components and data, not code
4. **Alternatives considered** — rejected options and why (this is the decision record; no separate ADR)
5. **Open questions** — anything unresolved from Phase 1
6. **Test list** — concrete scenarios; becomes canon-tdd step 1

One page unless genuinely warranted. No implementation code, no speculative phases.

## Phase 3 — Pushback

Before presenting the draft as final, critique it adversarially. Present numbered challenges for the user to accept or reject:

- Contradictions between sections
- Ambiguity an implementer would have to guess at
- Scope: anything here that's really a separate change? Anything the problem statement implies but the approach omits?
- Feasibility risks given the actual codebase

Revise per the user's rulings. A spec with unresolved Phase 3 challenges is not done.

## Exit gate

Implementation (canon-tdd) does not begin until the user approves the spec and the test list is non-empty.
