# Architecture review playbook

A detection catalogue. Start from a symptom you can see in the code. Each entry gives what it means, the principle behind it, the refactor, and the overcorrection to avoid. Entries are ordered by leverage, matching the priority list in SKILL.md. Jump to the flag you are looking at.

## Python calibration

The principles are language independent. In Python a few land differently:

- **Hiding is by convention.** A leading underscore is a promise, and duck typing lets callers reach into anything. Judge leakage by reading how data flows, not by where the underscores are.
- **Type hints are documentation.** Missing hints, bare `Any`, and untyped dicts passed between modules are real obscurity. The type checker proves less than a compiler would, so judge the design itself.
- **EAFP is idiomatic.** A `try/except` around a dict lookup is ordinary control flow. The target of "define errors out of existence" is an API that raises for a condition it could have made normal, forcing every caller to handle it.
- **Anaemic design is the common route to a shallow module.** Dataclasses or dicts holding state while the behaviour lives in free functions. `@property` pairs that add interface and hide nothing. `**kwargs` signatures that conceal the real interface.

## Contents

1. [Shallow module](#1-shallow-module)
2. [Information leakage](#2-information-leakage)
3. [Temporal decomposition](#3-temporal-decomposition)
4. [Overexposure](#4-overexposure)
5. [Pass-through method](#5-pass-through-method)
6. [Pass-through variable](#6-pass-through-variable)
7. [Conjoined methods](#7-conjoined-methods)
8. [Complexity exported to callers](#8-complexity-exported-to-callers)
9. [Special-general mixture](#9-special-general-mixture)
10. [Repetition](#10-repetition)
11. [Special cases and errors as complexity](#11-special-cases-and-errors-as-complexity)
12. [Comment repeats code](#12-comment-repeats-code)
13. [Implementation detail in the interface](#13-implementation-detail-in-the-interface)
14. [Hard to describe](#14-hard-to-describe)
15. [Vague name](#15-vague-name)
16. [Hard to pick a name](#16-hard-to-pick-a-name)
17. [Nonobvious code](#17-nonobvious-code)

## 1. Shallow module

Principle: modules should be deep.

**Symptom.** A class or function whose interface is about as complex as its implementation. In Python: classes that are mostly property getters and setters over fields; dataclasses holding state while the behaviour lives in free functions; manager, helper, or util classes wrapping a couple of calls; a signature as hard to learn as inlining the body; callers that must make several calls in a fixed order to get one outcome.

**Cost.** A module's cost is its interface and its benefit is what it hides. A shallow module pays full interface cost and hides little, so it adds cognitive load and buys no abstraction. Many shallow modules also force callers to orchestrate them, which drives change amplification.

**Refactor.** Make it deeper: more functionality behind the same or a simpler interface, so callers say what they want and the module handles how. Merge shallow modules that are always used together. Absorb a caller-side sequence into one call. Replace a knob with a sensible default. Show the resulting interface and count what the caller no longer has to know.

**Overcorrection.** Deeper means interface simpler than implementation. Merging unrelated things, or two concerns that change for different reasons, builds a god module that is worse than the start. Depth is a ratio; inflating the implementation misses the point.

Related: pass-through method, conjoined methods, overexposure.

## 2. Information leakage

Principle: information hiding. When you find real leakage it is usually the top finding.

**Symptom.** One design decision appears in two or more modules, so they must change together. In Python: the same file, wire, or date format parsed or emitted in several places; magic column indices or dict keys known to several modules; one module builds a structure and another must know its layout to consume it; two classes encoding the same assumption about units, ordering, or protocol. The test: if this decision changed, how many files would need to change, and would you find them all?

**Cost.** The shared decision is a dependency the type system will miss, so it produces change amplification and, worse, unknown unknowns: someone changes one copy and the others drift silently.

**Refactor.** Put the decision behind one module that owns it. The format lives in one parser and serialiser. The schema lives behind one accessor. The ordering assumption is enforced in one place. Other modules depend on that module's interface.

**Overcorrection.** Shared knowledge of a stable fact, such as a mathematical constant or a protocol that will never change, is fine, and centralising it adds a shallow indirection. Hide a decision that will plausibly change. Leave a fixed fact alone.

Related: temporal decomposition, repetition, conjoined methods.

## 3. Temporal decomposition

Principle: information hiding. Decompose by knowledge, not by execution order.

**Symptom.** The module structure mirrors the order operations run in. The classic shape is separate read, process, and write modules where the format of the data has to live in both the reader and the writer. In Python, a pipeline of stage functions or classes where each stage re-derives the same structural assumption.

**Cost.** Splitting by time forces the shared knowledge to leak across the stages, so a format change means changing every stage that touches it, with drift risk.

**Refactor.** Organise around knowledge. The thing that knows the format of X reads and writes it, so that knowledge lives in one module. The pipeline becomes a thin coordinator over knowledge-owning modules.

**Overcorrection.** A pipeline whose stages share no knowledge, each transforming a stable intermediate, is fine. The smell is shared knowledge split across time-ordered units, not the existence of a pipeline.

Related: information leakage, shallow module.

## 4. Overexposure

Principle: make the common case simple.

**Symptom.** The common case forces the caller to learn or supply things only the rare case needs. In Python: many required parameters where most callers want the same defaults; an `__init__` demanding configuration objects for the ninety percent case; advanced options inline with everyday ones; `**kwargs` that make the caller guess what is accepted.

**Cost.** Every caller pays the learning cost of features they will never use.

**Refactor.** Sensible defaults and a minimal required signature for the common case. Advanced features move to a separate, optional path: keyword arguments with defaults, a builder, or a separate entry point.

**Overcorrection.** Splitting one coherent operation into many tiny entry points trades overexposure for a discovery problem. Defaults must be safe; a consequential choice hidden behind a default is its own trap.

Related: shallow module, nonobvious code.

## 5. Pass-through method

Principle: different layer, different abstraction.

**Symptom.** A method that calls another method with the same or nearly the same signature and returns its result. In Python, a service or manager whose methods each forward one to one to a repository or client. A strong tell: most of a class's public methods are one-line delegations.

**Cost.** The method adds interface without adding abstraction. Two adjacent layers express the same abstraction, so the upper one is pure cost, and the signatures must stay in lockstep.

**Refactor.** Remove the layer, or give it a real job. Expose the lower object directly, or make the upper method combine several lower calls, enforce an invariant, or translate to a different abstraction. A method that still only forwards after the change should go.

**Overcorrection.** A thin forwarding layer that is a real boundary stays: a public facade that shields callers from internal churn, or an anti-corruption layer translating an external model into yours. A boundary changes the abstraction or isolates change. A pass-through repeats the abstraction for nothing.

Related: pass-through variable, shallow module.

## 6. Pass-through variable

Principle: different layer, different abstraction.

**Symptom.** A variable threaded through a chain of functions so that something deep down can use it. Every function in the middle accepts it and passes it on untouched. In Python, the parameter in five signatures along a call path that is only read at the bottom.

**Cost.** Every intervening function depends on a thing that is not theirs, and a new deep-down need means editing the whole chain.

**Refactor.** Get the value to where it is needed without threading it through everyone: a context object the relevant code already has, the object that owns the deep code, or for a read-only cross-cutting value a well-scoped module-level configuration. The middle functions stop mentioning it.

**Overcorrection.** A grab-bag context object that accumulates every loosely related value is its own obscurity. Keep context objects coherent and minimal.

Related: pass-through method, information leakage.

## 7. Conjoined methods

Principle: decomposition.

**Symptom.** Two methods so interdependent that neither can be understood alone: shared mutable state, an implicit ordering contract, or detailed assumptions about each other's internals. In Python, methods that communicate through instance attributes set as side effects instead of through parameters and return values.

**Cost.** The unit a reader must hold in their head is both methods plus their hidden contract. The split gives the appearance of decomposition without the benefit.

**Refactor.** Make each method understandable on its own: explicit arguments and return values instead of shared state, and no hidden ordering. If they are one operation split arbitrarily, merge them.

**Overcorrection.** Merging two large methods can produce one long procedure that is harder to follow. Fix the communication first. Some coupling is intrinsic; the target is understandable independently, not zero shared context.

Related: shallow module, nonobvious code.

## 8. Complexity exported to callers

Principle: pull complexity downward.

**Symptom.** A module keeps its own implementation simple by pushing work, decisions, or cleanup onto every caller. In Python: callers must remember to call `close()` because there is no context manager; callers must check a sentinel or status; callers must pass configuration the module could default; the same post-processing appears at every call site because the module returns something half finished.

**Cost.** One simplification inside the module is paid for at every call site, and each caller can get it wrong.

**Refactor.** Pull the complexity down behind the interface. A context manager so cleanup cannot be forgotten. A finished result instead of a half-finished one. The sensible default. The common condition handled internally. The caller's job shrinks to stating intent.

**Overcorrection.** Pull down what simplifies the interface. A decision that belongs to the caller stays with the caller; absorbing it forces the module to know things it should not and breeds special-case parameters.

Related: overexposure, special-general mixture, special cases and errors.

## 9. Special-general mixture

Principle: separate general-purpose and special-purpose code.

**Symptom.** Special-purpose logic inside a general mechanism. In Python: a generic utility, base class, or framework component with a branch for one caller's case; a reusable function hardcoding one application's keys, formats, or policy; a generic component importing from a specific feature module.

**Cost.** The general mechanism is coupled to the special case, so it is harder to reuse and to read, and the special case is harder to find.

**Refactor.** Pull the special-purpose code up into a layer that uses the general mechanism. The general code exposes a case-agnostic interface. The special behaviour is composed on top.

**Overcorrection.** This is in tension with YAGNI. General enough means serving today's needs cleanly. A mechanism made abstract for users who do not exist yet is usually shallower and more obscure.

Related: repetition, complexity exported to callers.

## 10. Repetition

Principle: a missing abstraction.

**Symptom.** A nontrivial chunk of code appears in several places, so a change must be made in all of them. In Python: copy-pasted blocks with small edits; the same validation or transform inlined at several call sites; parallel if-ladders encoding the same rule.

**Cost.** Change amplification, plus drift: three of four copies get updated and the fourth rots into a bug.

**Refactor.** One well-named function that everyone calls. When the repetition is structural, the same shape with different details, the abstraction takes the varying parts as parameters.

**Overcorrection.** Incidental duplication, two pieces of code that look alike today but represent different decisions, should stay apart. A wrong abstraction is worse than duplication. If the shared concept has no clean name, leave the copies and revisit when the pattern is real.

Related: special-general mixture, information leakage.

## 11. Special cases and errors as complexity

Principle: define errors out of existence.

This principle is the most dangerous to misapply. It means redesign the contract so the condition is normal and needs no handling. It never means catch and ignore. An I/O failure, a real validation error, a programming bug, or a violated invariant is still surfaced. When in doubt, surface the error.

**Symptom.** Special-case branches and exception handling for conditions that could have been ordinary. In Python: an API that raises for benign cases callers must wrap, such as a `KeyError` where a default would do, or an error when removing something that is absent; `if x is None` checks scattered across call sites because a function might return `None`; `Optional` threaded everywhere because one function will not commit to a value; the same try/except boilerplate at every call site.

**Cost.** Every special case is a branch every caller must know about, and each unhandled one is a latent bug. Most exceptions are defined into existence by an API choice, and a different design makes them never arise.

**Refactor.**

- Make the edge case normal. Removing a missing item is a no-op. A range query clamps to bounds. A lookup returns a documented default.
- Return a total result. If a function can always return something meaningful, such as an empty collection or a defined default, callers stop checking.
- Mask low. Handle a condition once, deep in the module positioned to deal with it, so nothing above sees it.
- For an unrecoverable condition, fail fast and loud. A fake normal value hides a real failure.

**Overcorrection.** Change the contract, never the handling alone. If the case cannot legitimately be made normal, the error stays. Idiomatic EAFP is fine. When an `Optional` is removed in gradually typed Python, the function must really be total, or a visible check has become a hidden crash.

Related: complexity exported to callers, nonobvious code.

## 12. Comment repeats code

Principle: comments describe what the code cannot say.

**Symptom.** A comment restating the adjacent code: `# increment count` over `count += 1`, a docstring that respells the function name.

**Cost.** Reading volume and maintenance with zero information, and it trains readers to skip comments, including the useful ones.

**Refactor.** Delete it, or replace it with what the code cannot express: the why, units and ranges, invariants and preconditions, what a value means, a non-obvious consequence.

**Overcorrection.** Ousterhout argues for comments that carry non-obvious information, especially on interfaces and on what member variables represent. Cut redundancy, keep meaning.

Related: implementation detail in the interface, nonobvious code.

## 13. Implementation detail in the interface

Principle: separate interface comments from implementation comments.

**Symptom.** A docstring meant for callers that explains the algorithm, internal data structures, or which private helpers it calls.

**Cost.** Callers may come to depend on stated internals, every reader of the interface carries details that are not theirs, and the docstring lies as soon as the internals change.

**Refactor.** The docstring describes what the thing does and how to use it: the abstraction, the contract, parameters, returns, errors, usage notes. Implementation comments live inside the body.

**Overcorrection.** Some implementation-sounding facts are part of the contract, such as complexity bounds or thread safety. Those belong in the interface comment. The line is what a user needs to know.

Related: comment repeats code, overexposure.

## 14. Hard to describe

Principle: difficulty of description is a design smell. Treat it as structural.

**Symptom.** Documenting a variable or method completely needs a long comment full of caveats: "returns the user, unless X, in which case the group, unless Y, in which case None, and also mutates Z".

**Cost.** A complicated description means a complicated thing: a fuzzy abstraction, too many responsibilities, or hidden side effects. The hard-to-write comment is early design feedback.

**Refactor.** Simplify the thing until it is easy to describe. Split mixed responsibilities. Remove the side effect. Make the return total. Narrow the contract.

**Overcorrection.** A subtle algorithm or a hairy external protocol needs real explanation, and that is essential complexity. The smell is length that comes from a muddled design rather than a hard problem.

Related: shallow module, conjoined methods, hard to pick a name.

## 15. Vague name

Principle: choosing names. Only when a name misleads or hides information.

**Symptom.** A name that carries little information: `data`, `obj`, `info`, `tmp`, `val`, `result`, `handle`. Worse, a misleading one: a `count` that is an index, a `users` that is one user, or a name that collides in meaning with another.

**Cost.** Obscurity. The reader has to look elsewhere to learn what the thing is, and a misleading name plants a wrong assumption that becomes a bug.

**Refactor.** Name it for what it is, with the unit, the role, or the entity: `elapsed_ms`, `selected_user`. Use the same name for the same concept everywhere.

**Overcorrection.** Adequate names stay. Short conventional names for short-lived locals are fine. Over-long names hurt readability.

Related: nonobvious code, hard to pick a name.

## 16. Hard to pick a name

Principle: difficulty of naming is a design smell.

**Symptom.** Every candidate name feels partial or wrong, or the honest name has "and" in it: `process_and_save_and_notify`.

**Cost.** The entity has a compound or fuzzy responsibility. That is a design problem rather than a vocabulary problem.

**Refactor.** Use the difficulty as feedback. An "and" in the honest name is a hint to split. A fuzzy concept gets sharpened until a clean name appears.

**Overcorrection.** Some well-formed things live in a domain with no established term. Invent a reasonable name and define it in a comment. Restructure when the awkwardness reflects a muddled responsibility.

Related: hard to describe, shallow module.

## 17. Nonobvious code

Principle: code should be obvious. The catch-all for obscurity.

**Symptom.** A reader has to work hard or guess to see what the code does or means. In Python: clever one-liners and dense comprehensions packing several steps; reliance on non-obvious truthiness or implicit conversion; behaviour that depends on a side effect or global state the reader cannot see; results that depend on subtle ordering. The test: would a competent developer guess wrong on first read?

**Cost.** High cognitive load, and a wrong guess is an unknown-unknown bug.

**Refactor.** Make the obvious reading the correct one: better names and types, a short comment stating the non-obvious why, a dense expression unpacked into named steps, a hidden dependency passed explicitly. Prefer clearer code over explained code.

**Overcorrection.** Obvious is relative to a competent reader of this codebase. Idiomatic constructs stay idiomatic. A subtle algorithm may be irreducibly non-obvious, and there a clear comment beats a forced rewrite.

Related: vague name, conjoined methods, hard to describe.
