---
name: design-rules
description: The design questions applied when writing a spec's approach, in the refactor step of TDD, and as the second lens of review. Consult when shaping an interface, deciding whether to add an abstraction, parameter, or branch, or judging a diff for complexity.
---

# Design rules

Complexity is the enemy. Ask these while writing, not as a checklist afterwards.

- **Is the module deep?** What a caller must know is much less than what the module hides. A function whose body is shorter than the words needed to describe it is collapsed into its caller. A module whose interface is as wide as its implementation is merged into a caller or a neighbour.
- **Could a reviewer follow this diff without reading the rest of the module?** If not, the diff is doing too much, or it needs a comment saying why.
- **If you removed this parameter, option, or branch, who would notice?** If nobody, remove it.
- **Are you patching around a design problem?** Fix the interface. When that is out of scope, file an issue and say so.
- **Before a try/except or a null check: can the interface change so the error cannot happen?** Make the case normal, return a total result, or handle it once low in the module. A real failure still surfaces.
- **One adapter is a hypothetical seam. Two adapters is a real one.** Add an interface only when a second implementation exists.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across its callers, it was earning its keep.
- **Complexity goes down, not out.** When the choice is a simpler interface or a simpler implementation, take the simpler interface. A caller that must call things in the right order, check a result, or pass a setting it does not care about is carrying the module's complexity.
- **Functional core, imperative shell.** Pure logic takes data and returns data. Effects live at the edges. Test the core directly and the shell thinly.
- **Strategic DDD only.** The project's language lives in CONTEXT.md and contexts are module boundaries. Aggregates, repositories, and domain events are out unless a spec argues for them.
- **Easy to delete beats easy to extend.** Design for the change you can name today.
- **The change test.** For each change you can name, count the files that would move. One is good. Many means a decision has leaked.
