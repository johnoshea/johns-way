---
name: debugging
description: Systematic debugging for any bug, failing test, error, build failure, or unexpected behaviour. Consult before proposing any fix, especially when a quick fix seems obvious.
---

# Debugging

No fix until the cause is understood.

1. **Read the whole error.** The full message, the complete stack trace, the line numbers. Before any theory.
2. **Reproduce it on demand.** If it cannot be triggered reliably, gather more data first.
3. **Check what changed.** Recent commits, new dependencies, config, environment. A recent change is the most likely cause.
4. **Find the cheapest test that settles the question**, and run it before adding any instrumentation. Often that is one command, one existing test with one input changed, or one print.
5. **Locate before investigating.** On a path through several components, log what enters and leaves each boundary, run once, and find the failing layer. Then investigate only that layer.
6. **Compare against working code.** Find the nearest thing that works and list every difference, however small.
7. **One hypothesis at a time.** State it before touching code: "X, because Y." Test it with the smallest change. Wrong? Revert fully, then form the next one. Fixes never stack.
8. **Write the failing test that reproduces the bug**, then fix at the cause with the least change. The tdd skill applies.
9. **Say why it happened.** A passing test with an unexplained cause is a symptom fix, and is not done.

**Three strikes.** Three failed fixes means this is a design problem, not a bug. Stop and put the design question to the user before a fourth attempt.

**No root cause found.** Timing, environment, and external systems sometimes leave none to find. Treat that as a claim needing evidence: state what was investigated, handle the failure explicitly with a retry, a timeout, or a clear error, and add the logging that would settle it next time.

An obvious one-line fix still gets the failing test first. The rest of the method is skipped.
