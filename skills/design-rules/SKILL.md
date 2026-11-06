---
name: design-rules
description: The design questions applied when writing a spec's approach, in the refactor step of TDD, and as the second lens of review. Consult when shaping an interface, deciding whether to add an abstraction, parameter, or branch, or judging a diff for complexity.
---

# Design rules

Complexity is the enemy. Ask these while writing, not as a checklist afterwards.

- **Is the module deep?** What a caller must know is much less than what the module hides. A function whose body is shorter than the words needed to describe it is collapsed into its caller. A module whose interface is as wide as its implementation is merged into a caller or a neighbour.
- **Could a reviewer follow this diff without reading the rest of the module?** If not, the diff contains too much, or it needs a comment saying why.
- **If you removed this parameter, option, or branch, who would notice?** If nobody, remove it.
- **Are you patching around a design problem?** Fix the interface. When that is out of scope, file an issue and say so.
- **Before a try/except or a null check: could you change the interface so the error cannot happen?** Make the case normal, return a total result, or handle it once low in the module. Still surface a real failure.
- **One adapter is a hypothetical seam. Two adapters is a real one.** Add an interface only when a second implementation exists.
- **The deletion test.** Imagine deleting the module. If no complexity is added elsewhere, it was a pass-through. If the same complexity must be repeated in its callers, it was worth keeping.
- **Push complexity down, not out.** When the choice is a simpler interface or a simpler implementation, take the simpler interface. A caller that must call things in the right order, check a result, or pass a setting it does not use contains complexity that belongs in the module.
- **Functional core, imperative shell.** Pure functions take data and return data. Keep effects at the edges. Test the core directly and the shell thinly.
- **Strategic DDD only.** The project's terms are in CONTEXT.md, and each context is a module boundary. Use aggregates, repositories, and domain events only when a spec contains a reason for them.
- **Prefer easy to delete over easy to extend.** Design for the change you can name today.
- **The change test.** For each change you can name, count the files you would have to change. One is good. Many means a decision has leaked.
- **Where is this fact recorded?** If a fact is only in a comment, put it in the code: a name, a type, or a test. Then use the comment for the reason.
- **Is every attribute's purpose stated?** Give each class attribute a comment with what its value is and what it is used for.
- **Is this value one of a known set?** If a value is always one of a known set, make it a type, never a bare str or int. Add its values to CONTEXT.md.
- **Would a reader parse this twice?** Turn an expression the reader must parse twice into a named function. A lambda inside a dense line is the usual case.
- **Would a reader ask why?** Give the reason for any choice a reader would question. For a mutable dataclass among frozen ones, add a comment with the reason it is mutable.
