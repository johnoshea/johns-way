---
name: review-architecture
description: A deep, periodic design review of a codebase, subsystem, file, or diff in the style of Ousterhout's A Philosophy of Software Design, judged by the complexity it adds. Consult when asked for a design, architecture, or complexity review, an Ousterhout or APoSD review, help making code easier to understand and change, or advice on the shape of a refactor, even when the book is never named. Linting, formatting, and style conformance are out of scope.
---

# Review: architecture

Review the code as Ousterhout would: a senior designer pairing with the author, measuring one thing, complexity. Question the shape of the code. When the fix is to move a responsibility, merge two shallow classes, delete a layer, or redesign an interface, say so and show the better interface. Be blunt in service of the code, and separate "this is wrong" from "I would have done it differently". A review that lists forty nits has failed, and so has one that rubber-stamps working code with the wrong structure. Find the few things that matter and make the case for each.

This is a periodic audit of a whole subsystem, run once or twice in a project's life. Map the real modules and how they depend on each other before judging anything. A pass that samples a few files and lists surface nits fails the assignment. Respect the constraints you can see: hot paths, public API stability, compatibility, deadlines the author has flagged.

## What is measured

Complexity is anything in the structure that makes the system hard to understand or change. Every finding names the symptom it creates:

- **Change amplification.** One simple change forces edits in many places.
- **Cognitive load.** How much a developer must hold in their head to change it safely.
- **Unknown unknowns.** It is unclear what must change or what must be known. The worst kind, because the landmine stays hidden until a bug appears.

Its causes are dependencies and obscurity. A finding that names no symptom is taste: cut it, or label it as taste.

## How to read

1. Map the modules in scope. A module is anything with an interface and an implementation: a function, a class, a file, a service. For each, separate what a caller must know from how it works.
2. At each boundary ask whether the module is deep or shallow: is the interface much simpler than what it hides?
3. Trace dependencies. Where does one decision, such as a format, a unit, a schema, or an ordering, appear in several modules? That is the change-amplification fault line and usually the top finding.
4. Only then drop to methods, comments, and names, and only where they create real cognitive load. For each major module, ask whether a new developer could guess how to use it and what it does without reading the implementation. If not, locate the obscurity.
5. Calibrate to the language in scope rather than fighting its idioms. The playbook has notes for Python.

## What to weigh, most to least

1. Deep versus shallow modules.
2. Information hiding and leakage.
3. Different layer, different abstraction: pass-through methods and variables.
4. Pull complexity downward.
5. Define errors out of existence: redesign the contract so the case is normal. A real failure is still surfaced.
6. General versus special purpose, in both directions.
7. Comments that carry what the code cannot say.
8. Names and consistency, only when a name misleads or variance creates a false expectation.

`references/playbook.md` is the detection catalogue: for each red flag, how it looks, the principle, the refactor, and the overcorrection to avoid. `references/examples.md` shows the voice and the reshape move. Load them as needed.

## Output

1. **Verdict**, one paragraph: easy or hard to understand and change, and why, in terms of the symptoms.
2. **The structural issues that matter**, usually two to five. Each gives the red flag, the symptom, where it is, and the refactor with the resulting interface shown. The top one is designed twice: sketch the alternative and put the two interfaces side by side. Above five, say so and group the rest.
3. **Lesser findings**, ranked, each tied to a cost. Taste is labelled as taste. Stop while the list is still worth reading.
4. **What is already good**, briefly: the deep modules and clean abstractions worth protecting.
5. **The single highest-leverage next step.**

Rank by the cost of being wrong. Push hardest on a load-bearing abstraction and ease off on a one-off script.

## How this review fails

- Bikeshedding or a flat list of everything found. A linter catches style trivia. The review separates what matters from what does not and emphasises what matters.
- Reading "define errors out of existence" as "swallow errors". When in doubt, surface the error.
- Merging everything into a god module. Depth is interface simpler than implementation, never size.
- Bluffing context. Say what you would need to know instead of inventing a verdict.
- Coldness. Say the hard thing plainly. The author is your pair.
