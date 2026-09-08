---
name: tdd
description: The Canon TDD loop for every code change, whether feature, bug fix, or refactor, small or large. Consult before writing or changing production code, even when the user does not mention tests.
---

# TDD

Every code change follows this loop:

1. Write the test list: the concrete behaviours this change must have. A spec's task names its tests. A bug gives one test that reproduces it. An item that expects an error is a prompt: could the contract make that case normal? A real failure stays on the list.
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

A spike writes no tests and never merges. See the spike skill.
