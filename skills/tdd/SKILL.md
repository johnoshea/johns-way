---
name: tdd
description: The Canon TDD loop for every code change, whether feature, bug fix, or refactor, small or large, and what a test must prove to earn its place. Consult before writing or changing production code, even when the user does not mention tests, and when judging a test someone else wrote.
---

# TDD

Every code change follows this loop:

1. Write the test list: the concrete behaviours this change must have, each with the defect it catches. A spec's task names its tests. A bug gives one test that reproduces it. An item that expects an error is a prompt: could the contract make that case normal? A real failure stays on the list.
2. Pick one item. Write it as a runnable test.
3. Run it and watch it fail. Show the failing output. A test that passes at once is testing nothing: fix the test.
4. Write the least code that makes it pass, along with every earlier test.
5. Refactor as a separate step, with the tests green before and after. Apply the design-rules skill here.
6. Cross the item off. Repeat until the list is empty.

Rules:

- One failing test at a time.
- A bug fix starts with the failing test that reproduces the bug. The fix comes second.
- Scale the loop to the change. A feature works through a list. A one-line fix gets one test. A change with no new behaviour, such as a rename, gets no new test; the existing tests are the check.
- When a test is hard to write, the interface is wrong. Change the interface before writing a contorted test.
- Test through the module's interface. A test that reaches past it into internals is testing the wrong shape.
- Never mock what you own. Fake the boundary the code does not own: the network, the clock, the filesystem, another process.
- Match the project's existing test layout and naming. Read a neighbouring test file before writing the first test.

## What a test proves

A test earns its place when a plausible defect in the code under test would make it fail, and no other test would fail on that defect. The deletion test for a test: imagine deleting it, then name the defect that now goes uncaught. A real answer points at a branch or boundary in the code under test and says what wrong behaviour there trips the assertion. The test is vacuous when the answer is none, the same defect as another test, a broken library, a fake returning a different value, or a refactor.

Shapes that cannot fail:

- An assertion that holds by construction: a value compared with itself, an isinstance check on a value the test built, a check that a result is not None when the exact value is known.
- An expected value computed by the same logic as the code. Write the literal.
- An assertion that the fake's fixed return value satisfies, whatever the code in between does.
- An error check that accepts any exception.
- Every collaborator the module owns mocked, and an assertion that a mock was called.
- Call counts, private state, or log lines asserted. Only a refactor fails it, and a refactor is not a defect.

Shapes that repeat another test:

- No assertion, on a path another test already runs.
- A second parameter row on the same branch. A row earns its place by reaching a boundary the others miss: empty, zero, negative, largest, unicode, another branch. Its id names that boundary. For many values, write a property test instead of rows.
- The same assertion through an entry point that only delegates.
- An assertion that is a subset of a sibling's.

Thin glue and pass-through wrappers get no test of their own. Such a test would exercise only its fakes.

In review, a test that cannot fail is a blocking finding. A test that repeats another is a note asking for its deletion.

A spike writes no tests and never merges. See the spike skill.
