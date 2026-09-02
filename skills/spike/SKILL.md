---
name: spike
description: Answering a feasibility question with throwaway code. Consult when the request is a question such as "can we", "is it possible", or "how hard would it be", and the output is an answer rather than code to keep.
---

# Spike

A spike answers a question. Its code never merges.

## Before starting

State in chat, in three lines: the question, the turn budget, and what evidence would answer it.

## During

Work on a throwaway branch, `git switch -c spike/<topic>`, or a worktree. No tests, no review, no design rules. Find out as cheaply as correctness allows. Commit on the branch as often as useful; none of it survives.

## Ending

End with a written answer of one paragraph in chat: what was tried, what was found, and the recommendation. If a spec exists, add the answer to its Alternatives considered or Open questions section and commit that.

Then delete the branch: `git switch main` and `git branch -D spike/<topic>`. Real implementation starts from main, test-first, on its own path through routing. It may read the spike before deletion. It never merges or cherry-picks it.

A spike that reaches its budget without an answer is reported as a failed spike, with what was learned. That is a result too.
