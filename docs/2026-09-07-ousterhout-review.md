# Three ideas from A Philosophy of Software Design, and where johns-way holds them

The plugin meets design ideas in two places. The periodic review, `skills/review-architecture/`, runs on request once or twice in a project's life and carries a playbook and worked examples. The everyday flow runs on every task: the design-rules skill, applied by the spec's Approach section, by the refactor step of TDD, and by the reviewer's second lens.

The same pattern holds for all three ideas. The periodic review has each one in full. The everyday flow has each one in a single line, or not at all. Each proposal below moves one sentence of the principle into the everyday skill at the moment the decision is actually made: the test list, the spec's Approach, the refactor step.

None of the ideas can live in a hook. Each is a judgment about whether a case is legitimately normal, whether an interface is simpler than what it hides, or whether a second design is worth having. Hooks hold mechanical rules, so these go in skills.

Line budget after every proposal below, against the limits in CLAUDE.md:

| File | Now | After | Limit |
| --- | --- | --- | --- |
| design-rules/SKILL.md | 20 | about 24 | 60 |
| spec/SKILL.md | 40 | about 46 | 60 |
| tdd/SKILL.md | 27 | 28 | 60 |
| requirements/SKILL.md | 36 | 37 | 60 |
| routing/SKILL.md | 38 | 38 | 40 |
| All skills together | 561 | about 575 | 800 |

## 1. Define errors out of existence

### What we have

Everyday flow:

- `skills/design-rules/SKILL.md` has one bullet: "Before a try/except or a null check: can the interface change so the error cannot happen?"
- `agents/reviewer.md` lists, under the design-rules lens, "error handling that an interface change would remove".
- `skills/tdd/SKILL.md` says "When a test is hard to write, the interface is wrong." That is the same instinct from the test side.
- `skills/debugging/SKILL.md`, under "No root cause found", says to "handle the failure explicitly with a retry, a timeout, or a clear error". That is the correct opposite case: a real failure surfaces.

Periodic review:

- `skills/review-architecture/SKILL.md` weighs it fifth of eight: "redesign the contract so the case is normal. A real failure is still surfaced." Under "How this review fails" it names the misreading: "Reading 'define errors out of existence' as 'swallow errors'."
- `references/playbook.md` entry 11 gives the symptom, the cost, four refactors (make the case normal, return a total result, mask low, fail fast for the unrecoverable), and the overcorrection. It opens with "This principle is the most dangerous to misapply."
- `references/examples.md` example 3 shows the discount lookup with three exceptions collapsed into a total result.

### Assessment

The periodic review covers this idea fully. The everyday rule has two weaknesses.

It fires late. The bullet asks the question at the moment a try/except is about to be written. By then the contract exists and the first callers may exist. Ousterhout's point is that errors are defined into existence by the contract, so the question belongs where the contract is decided: the test list and the spec's Approach.

It carries no guard. The playbook calls this the principle most dangerous to misapply. The reviewer agent loads design-rules and never loads the playbook, so it applies the rule without the warning.

### What we might change

**tdd, step 1.** After "A bug gives one test that reproduces it.", add one sentence:

> An item that expects an error is a prompt: could the contract make that case normal? A real failure stays on the list.

The test list is the first place the contract is written down. This puts the question there.

**design-rules, the error bullet.** Replace it with:

> **Before a try/except or a null check: can the interface change so the error cannot happen?** Make the case normal, return a total result, or handle it once low in the module. A real failure still surfaces.

The second sentence gives the three moves. The third is the guard the reviewer needs.

**Rejected: a hook that flags a new `except` or `is None` in a diff.** It would fire on every real failure too, and the judgment it needs is whether the case is legitimately normal. That is not mechanical.

## 2. Deep modules

### What we have

Everyday flow:

- `skills/design-rules/SKILL.md`, first bullet: "A function whose body is shorter than the words needed to describe it is collapsed into its caller. A module that hides a lot behind a small interface is kept." That second sentence is the definition of a deep module without the word.
- Four more bullets push toward fewer and deeper modules: the parameter removal question, the one-adapter rule, the deletion test, and functional core with imperative shell.
- `agents/reviewer.md` lists "abstractions that do not earn their keep" and "seams with one adapter".
- `skills/requirements/SKILL.md` drafts "a list of three to six modules" when a round settles nothing. That counts modules and says nothing about their interfaces.
- `skills/spec/SKILL.md`, Approach: "Components and data. Which parts are core, taking data and returning data, and which are shell, performing effects." Then "No code in it."

Periodic review:

- `skills/review-architecture/SKILL.md` weighs "Deep versus shallow modules" first of eight, and step 2 of "How to read" asks at each boundary "is the interface much simpler than what it hides?"
- Playbook entries 1, 3, 4, 5, 6, 8 and 13 are all forms of shallowness. Entry 8 is "pull complexity downward". Example 1 shows a five-method report writer collapsed to one call.
- "How this review fails" guards the overcorrection: "Depth is interface simpler than implementation, never size."

### Assessment

The everyday rule has the concept without the word and without the test. "Earns its keep" reads as "is it worth having", and a shallow module with a good name passes that. The test is a ratio: what a caller must know against what the module hides. Naming the ratio makes it checkable.

Depth is judged too late. The spec names components and says which are core and which are shell, but never states what a caller gives each one and gets back. "No code in it" has been read as no interfaces. So the first place a component's interface appears is the code, and the reviewer judges it after the fact. Depth is a property of the interface, and the interface can be written as one sentence in a spec.

The everyday rules have nothing on pulling complexity downward. That is the practice that produces depth: when the choice is a simpler interface or a simpler implementation, the interface wins.

### What we might change

**design-rules, first bullet.** Replace it with:

> **Is the module deep?** What a caller must know is much less than what the module hides. A function whose body is shorter than the words needed to describe it is collapsed into its caller. A module whose interface is as wide as its implementation is merged into a caller or a neighbour.

**design-rules, new bullet** after the deletion test:

> **Complexity goes down, not out.** When the choice is a simpler interface or a simpler implementation, take the simpler interface. A caller that must call things in the right order, check a result, or pass a setting it does not care about is carrying the module's complexity.

**spec, Approach.** After the core and shell sentence, add:

> For each component, one line saying what a caller gives it and gets back. That is its interface, judged for depth here, before any code exists.

This keeps "No code in it" and gives the reviewer's first lens something to check the interface against.

**routing, the medium design.** The chat design is "approach, files touched, tests". Change that phrase to "approach, any new interface in one line, files touched, tests". Same line count. Medium is the path whose criterion is that an interface changes, so it is where this matters most.

**reviewer.md, second lens.** Add "shallow modules" to the list, so the reviewer names the shape and not only the symptom.

## 3. Design it twice

### What we have

Periodic review:

- `skills/review-architecture/SKILL.md`, Output, item 2: "The top one is designed twice: sketch the alternative and put the two interfaces side by side." Example 1 does exactly that under the heading "Designed twice, the two interfaces side by side".

Everyday flow:

- `skills/spec/SKILL.md`, section 4: "Alternatives considered. Rejected options and why. This is the decision record."
- `skills/pull-requests/SKILL.md`: "Alternatives rejected, one line each, when there were any."
- `skills/routing/SKILL.md`, medium: "If the design involves a choice, ask it with AskUserQuestion and wait."
- `skills/requirements/SKILL.md`: "put a one-paragraph description and a list of three to six modules in front of the user and ask what is wrong." One draft.
- `docs/design.md` practises the idea on itself: "No Stop hook for uncommitted changes" records a rejected design and the reason.

### Assessment

This is the least covered of the three. Every everyday mention is a record of alternatives, written after the choice. Nothing makes a second design exist. Alternatives considered can honestly be empty when the first design was the only one thought of, and for a model that is the usual case: it commits to its first plan. The medium rule "if the design involves a choice" presumes a choice is already on the table.

Ousterhout's claim is that the second design is worth sketching even when the first looks fine, because comparing two exposes the weaknesses of each, and the comparison is on interfaces rather than implementations. The spec's pushback pass is a different thing. It reads one design as an adversary and never proposes another.

### What we might change

**spec, a step before Approach.** Add a short section, "Two designs", between the section list and Pushback:

> Before writing Approach, sketch two approaches that differ in where the interfaces fall. Compare them on the design rules: which has the deeper modules, which needs fewer special cases, which is easier to delete. Write the winner as Approach and the loser into Alternatives considered with the reason. When the design rules do not settle it, the choice is the user's: ask with AskUserQuestion and wait.

Alternatives considered then always has at least one real entry, and the last sentence keeps the CLAUDE.md gate: a choice the rules cannot settle is the user's.

**requirements, the draft.** Change "put a one-paragraph description and a list of three to six modules in front of the user and ask what is wrong" to two drafts and "ask which is closer and what is wrong with it". Comparing is easier than generating, which is the same reason the draft technique exists at all.

**Rejected: a commit-check rule that blocks a staged spec whose Alternatives considered section is empty.** It would enforce the record and not the comparison, a token entry passes it, and the crit gate already puts the section in front of the user.

**Medium path.** Left alone. See Decisions below.

## Decisions

Settled at review.

1. **Design twice applies to the spec only.** Medium is where most interface changes happen, but it is also the path built for speed. The rule goes into the spec skill first, and medium follows only if it earns its keep there.
2. **"Deep" is defined inline in the design-rules bullet, with no CONTEXT.md entry.** CONTEXT.md is the glossary of the plugin's own domain. "Deep" is Ousterhout's term for a property of the user's code.

## Consequences for the docs

Any of these is a behaviour change, so it also updates the Design rules and Skills sections of `docs/design.md` and the matching row of the README's skills table in the same commit.
