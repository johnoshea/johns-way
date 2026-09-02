---
name: reviewing-prs
description: Reviewing other people's pull requests with gh. Consult when asked to review a pull request, look over someone's change, or leave review comments.
---

# Reviewing pull requests

## Intent first

`gh pr view` for the description, the linked issue, and the discussion. The change is judged against what its author set out to do. If the intent is unclear, that is the first comment, before anything about the code.

## Then the diff

`gh pr diff`, and check the branch out when the diff alone is not enough. Read in this order:

1. **Correctness.** Does it do what the description says. Missing cases, broken invariants, wrong error handling, races. Run the tests.
2. **Tests.** Do they test the behaviour or the implementation. Would they fail if the change were reverted.
3. **Design.** The design-rules skill applied to the diff, weighted towards what is expensive to change later: interfaces, persisted shapes, boundaries.
4. **Everything else** goes unsaid unless asked. Style that a formatter or linter would catch is never a comment.

## Comments

One comment per finding, on the line it concerns, through `gh pr review --comment` or `gh api` for inline comments. Each says what is wrong, why it matters, and what would fix it. Questions when uncertain, statements when sure. A finding that applies in several places gets one comment with the list.

Say what is good when it is notably good, never as padding.

## Verdict

Approve or request changes only when the user asks. Otherwise leave the comments and summarise them to the user: the blocking findings first, then the rest, in one short list.
