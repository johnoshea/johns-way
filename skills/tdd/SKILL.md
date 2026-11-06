---
name: tdd
description: The Canon TDD loop for every code change, whether feature, bug fix, or refactor, small or large, and what a test must prove to earn its place. Consult before writing or changing production code, even when the user does not mention tests, and when judging a test someone else wrote.
---

# TDD

Use this loop for every code change:

1. Write the test list: the concrete behaviours this change must have, each with the defect its test would catch. For a spec task, use the tests named in the task. For a bug, write one test that reproduces it. If an item is an expected error, ask: could you change the contract so that case is normal? A real failure stays on the list.
2. Pick one item. Write it as a runnable test.
3. Run it and watch it fail. Show the failing output. A test that passes at once is testing nothing: fix the test.
4. Write the least code that makes it pass, along with every earlier test.
5. Refactor as a separate step, with the tests green before and after. Apply the design-rules skill here.
6. Cross the item off. Repeat until the list is empty.

Rules:

- One failing test at a time.
- Start a bug fix with the failing test that reproduces the bug. Write the fix second.
- Scale the loop to the change. For a feature, work through a list. For a one-line fix, write one test. For a change with no new behaviour, such as a rename, write no new test; the existing tests are the check.
- When a test is hard to write, the interface is wrong. Change the interface before writing a contorted test.
- Test through the module's interface. A test that reaches past it into internals is testing the wrong shape.
- Never mock what you own. Fake the boundaries you do not own: the network, the clock, the filesystem, another process.
- Match the project's existing test layout and naming. Read a neighbouring test file before writing the first test.

## What a test proves

A test earns its place when a plausible defect in the code under test would make it fail, and no other test would fail on that defect. The deletion test for a test: imagine deleting it, then name the defect that is no longer caught. A real answer is a branch or boundary in the code under test, and the wrong behaviour there that makes the assertion fail. The test is vacuous when the answer is none, the same defect as another test, a broken library, a fake returning a different value, or a refactor.

Shapes that cannot fail:

- An assertion that holds by construction: a value compared with itself, an isinstance check on a value the test built, a check that a result is not None when the exact value is known.
- An expected value computed by the same logic as the code. Write the literal.
- An assertion that the fake's fixed return value satisfies, whatever the code in between does.
- An error check that accepts any exception.
- Every collaborator the module owns mocked, and an assertion that a mock was called.
- Call counts, private state, or log lines asserted. It fails only on a refactor, and a refactor is not a defect.

Shapes that repeat another test:

- No assertion, on a path another test already runs.
- A second parameter row on the same branch. Add a row only for a boundary not covered by the other rows: empty, zero, negative, largest, unicode, another branch. Use the boundary as its id. For many values, write a property test instead of rows.
- The same assertion through an entry point that only delegates.
- An assertion that is a subset of a sibling's.

Write no test of its own for thin glue or a pass-through wrapper. Such a test would exercise only its fakes.

In review, a test that cannot fail is a blocking finding. A test that repeats another is a note asking for its deletion.

Write no tests in a spike, and never merge it. See the spike skill.
