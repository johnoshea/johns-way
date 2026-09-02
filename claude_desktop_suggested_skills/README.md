# Lean skill set — 5 skills

1. **canon-tdd** — the loop, simplicity rules, definition of done, test conventions
2. **writing-specs** — interrogate → draft → pushback; gates canon-tdd
3. **debugging**
4. **prs-and-commits**
5. **github-issues**

## Why simplicity is no longer a standalone skill

The triggering concern was correct: Claude consults skills for tasks it can't easily handle, and "write simple code" is precisely what Claude believes it already does — so a standalone simplicity skill undertriggers. It's now a section inside canon-tdd, which *does* reliably load because the CLAUDE.md line below forces consultation before any code change. That's the general pattern: cross-cutting rules ride inside a skill that has a real trigger moment, or live in CLAUDE.md itself.

(For the record, manual invocation does exist: naming a skill in your prompt — "apply the simplicity skill" — triggers it, as does wiring it to a slash command. But an architecture that needs you to remember an incantation is the wrong architecture.)

## Provenance

**debugging** lifts five things from Superpowers' systematic-debugging (compressed from its 296 lines to ~25): check-what-changed-first, boundary instrumentation to locate the failing layer before investigating it, compare-against-working-code, the three-strikes architecture rule, and the "no root cause" pressure valve. Deliberately not lifted: the triple-redundant enforcement sections (Iron Law / Red Flags / Rationalizations tables say "don't guess" three ways), the unverifiable impact stats, and the defense-in-depth companion technique — which adds validation at multiple layers after a fix and sits in direct tension with our simplicity rule ("handle the error states that can occur, not the ones that can't"). Its condition-based-waiting technique (replace arbitrary timeouts with condition polling) is worth remembering if flaky async tests become a problem — revive it as two lines in canon-tdd's test conventions then.

## writing-specs: provenance

The redesign borrows two mechanisms:
- **Phase 1 (Interrogate)** adapts Matt Pocock's grill-me: interrogate the requirements until they're sharp enough to act on, instead of letting the agent guess at missing details. The "batch 2–4, stop when answers stop changing the design" rule guards against the known failure mode of interrogation skills: hundreds of low-value questions.
- **Phase 3 (Pushback)** adapts Ovid's /paad:pushback: an adversarial pass over the draft for contradictions, ambiguity, scope problems, and omissions.

Deliberately *not* borrowed: Wayfinder's full map machinery (decision tickets on the issue tracker, multi-session orchestration). It solves a different problem — efforts too big and foggy for one session. Pocock himself routes small, well-understood features to grill-me instead. If you ever hit a genuinely multi-week ambiguous effort, install his actual plugin for the occasion rather than rebuilding it here.

## One line for CLAUDE.md (paste this)

> All code changes follow Canon TDD — consult the canon-tdd skill before writing any code. Non-trivial changes get a spec first — consult the writing-specs skill.

## Cut entirely, with the revival trigger for each

- database-migrations / deployment — revive the moment Claude starts touching either
- reviewing-prs — revive if Claude starts reviewing weekly
- ci-debugging — revive after the first CI failure that wastes 20 minutes
- error-handling / api-conventions — revive when you have settled conventions to encode
- wayfinder-style planning — install Pocock's plugin if a multi-session foggy project arrives

## Setup

Each file is a proto-SKILL.md with `[TODO: ...]` markers. Drop each into `.claude/skills/<name>/SKILL.md`, fill the TODOs, delete any TODO you can't answer yet.
