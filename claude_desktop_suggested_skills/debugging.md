---
name: debugging
description: Systematic debugging method. Consult when investigating any bug, failing test, error, build failure, or unexpected behaviour — before proposing any fix, especially under time pressure or when a "quick fix" seems obvious.
---

# Debugging

No fix proposals until the cause is understood.

1. **Read the actual error** — full message, complete stack trace, line numbers — before theorising.
2. **Reproduce reliably.** If you can't trigger it on demand, gather more data; don't guess.
3. **Check what changed.** `git diff`/`git log`, new dependencies, config — a recent change is the most likely cause.
4. **Locate before investigating** (multi-component paths — e.g. CI → build → deploy, API → service → DB): log what enters and exits each boundary, run once, identify the failing layer. Then investigate only that layer.
5. **Compare against working code.** Find the nearest similar thing that works and list every difference, however small — don't assume "that can't matter".
6. **One hypothesis at a time**: "I think X because Y", stated before touching code. Test it with the smallest possible change. Wrong? Revert fully and re-hypothesise — never stack fixes.
7. **Formalise the repro as a failing test** (canon-tdd), then fix at the cause, minimally.
8. **You're not done until you can say why** the bug happened — a passing test with an unexplained cause is a symptom fix.

**Three-strikes rule:** three failed fix attempts means this probably isn't a bug — it's a design problem. Stop and discuss the architecture with the user before attempting a fourth.

**Genuinely no root cause?** (truly environmental, timing-dependent, external): state what was investigated, handle it explicitly — retry, timeout, clear error — and add logging for next time. But treat "no root cause" as a claim requiring evidence; it usually means incomplete investigation.

Escape hatch: obvious one-line fixes still get the failing test first; skip the rest of the ritual.
