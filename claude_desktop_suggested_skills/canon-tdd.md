---
name: canon-tdd
description: Red-green Canon TDD workflow and simplicity rules for all code changes. Consult before writing or modifying any production code — features, bug fixes, refactors — even small ones, and even when the user doesn't mention tests. Also defines what "done" means and how tests are written in this repo.
---

# Canon TDD

Every code change follows this loop:

1. Write a **test list**: the concrete scenarios this change must handle. (If a spec exists, its test list is this list.)
2. Pick **exactly one**. Write it as a runnable test.
3. Run it. **Watch it fail.** If it passes immediately, the test is wrong — fix the test.
4. Write the **minimum** code to make it (and all prior tests) pass.
5. Refactor only as a separate, named step.
6. Repeat until the list is empty.

Rules:
- A bug fix starts with a failing test that reproduces the bug.
- Never more than one new failing test at a time.
- Show the red output before writing implementation.

## Simplicity

Applies to every step above, especially 4 and 5:

- No speculative abstraction. Inline until there are ~3 call sites.
- No options/config for a single caller. No interface with one implementation.
- Smallest diff that passes the tests. Prefer deleting code to adding it.
- No drive-by refactors outside the task's scope — note them, don't do them.
- Match the file's existing patterns before inventing new ones.
- Handle the error states that can occur, not the ones that can't.
- Explanations: what changed and why in a few sentences, not an essay.

## Definition of done

Before saying "done", "fixed", "works", or opening a PR:
- Run: `[TODO: test command]`, `[TODO: typecheck command]`, `[TODO: lint command]`
- Paste actual output, not a summary of expected output.
- "Should work" is banned — it was verified, or say explicitly what wasn't and why.

## Test conventions

- `[TODO: naming convention and file placement]`
- `[TODO: fixture/factory patterns; what to mock and what never to mock]`
- `[TODO: unit vs integration boundary in this codebase]`
