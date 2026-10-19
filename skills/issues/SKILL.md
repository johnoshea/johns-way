---
name: issues
description: Filing, reading, triaging, and updating GitHub issues with gh. Consult whenever the task involves an issue or ticket, when work found mid-task needs deferring, or when a spec or review produces follow-up work.
---

# Issues

Issues hold work that is not being done now: found while working, out of scope, or blocked. The spec's task list holds work being done now. A piece of work is in one place or the other, never both.

## Reading

An existing issue is the input to requirements. Read it, its comments, and anything it links before asking the user a single question.

## Filing

`gh issue create`, with a title in the imperative under 60 characters.

- Bugs: context, expected and actual behaviour, the smallest reproduction.
- Features: context, and acceptance criteria written as a test list. That list is the tdd skill's first step when the work starts.
- Follow-ups from a spec or a review: one issue per concern, linking the spec. Split rather than bundle.

Write for someone who was not in the session: the rule or the fact, never the episode. No session shorthand, no hostnames. Run the plainly skill on the title and body before `gh issue create`.

## Updating

Comment when something changes that a reader would need. Run the plainly skill on the comment before posting it. Never close an issue, mark it done, or record a decision in it unless the user said so in this session.

## When to file rather than fix

File when the fix is outside the current task's scope, when it needs a decision the user has not made, or when the design-rules skill says to fix an interface and that is out of scope. Say in one line that the issue was filed.
