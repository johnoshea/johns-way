---
name: spike
description: Answering a feasibility question with throwaway code. Consult when the request is a question such as "can we", "is it possible", or "how hard would it be", and the output is an answer rather than code to keep.
---

# Spike

A spike is for answering a question. Never merge its code.

## Before starting

State in chat, in three lines: the question, the turn budget, and what evidence would answer it.

## During

Work on a throwaway branch, `git switch -c spike/<topic>`, or a worktree. No tests, no review, no design rules. Find out as cheaply as correctness allows. Commit on the branch as often as useful; all of it is deleted at the end.

## Ending

End with a written answer of one paragraph in chat: what was tried, what was found, and the recommendation. If a spec exists, add the answer to its Alternatives considered or Open questions section and commit that.

Then delete the branch: `git switch main` and `git branch -D spike/<topic>`. Start real implementation from main, test-first, on its own path through routing. You may read the spike before you delete it. Never merge or cherry-pick it.

If the budget is used up without an answer, report a failed spike, with what was learned. That is a result too.
