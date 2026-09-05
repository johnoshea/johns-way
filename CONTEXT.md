# Glossary

**Path**: the size class a request is worked on, one of small, medium, full, or spike, each with its own process.
_Avoid_: tier, mode, track, level.

**Routing**: classifying a request onto a path before work starts.
_Avoid_: triage, sizing.

**Upgrade**: moving a request to a larger path mid-task, on one of three named triggers and with the user's confirmation.
_Avoid_: escalate, promote.

**Downgrade**: moving a request to a smaller path mid-task, at once and without asking.
_Avoid_: de-escalate, demote.

**Spec**: the one file per full-path feature, under `docs/specs/`, holding the design and its ordered task list.
_Avoid_: plan, design doc, RFC.

**Task**: one numbered line under a spec's Tasks heading, completed by exactly one commit.
_Avoid_: step, ticket, story.

**Trailer**: a Spec line and a Task line at the end of a commit message, marking the task the commit completes.
_Avoid_: tag, footer, label.

**Amendment**: a dated entry in a spec recording a change made during implementation and why.
_Avoid_: revision, edit, changelog.

**Check target**: the command a project runs to test and lint itself, found in its justfile or pyproject.toml.
_Avoid_: check command, check recipe, test suite.

**Check**: what every commit must pass, the dependency cooldown and then the check target.
_Avoid_: pre-commit, validation, gate.

**Cooldown**: the rule that a dependency version is adopted only once it is 14 days old.
_Avoid_: quarantine, embargo, waiting period.

**Session check-in**: the one message per session, after a time limit, that asks whether medium work should upgrade to full.
_Avoid_: reminder, timer, nudge.

**Gate**: a point where work stops and waits for the user: the crit round on a spec, the crit round after a review, and any question asked with AskUserQuestion.
_Avoid_: checkpoint, approval, sign-off.

**Definition of done**: running the check target, pasting its real output, and having README.md, CLAUDE.md, and CONTEXT.md describe what the code now does.
_Avoid_: done criteria, acceptance, DoD.

**Reviewer**: the plugin's subagent that reviews a finished change with fresh context, against its spec and the design rules.
_Avoid_: critic, auditor, second opinion.

## Relationships

A **Spec** holds many **Tasks**, and each **Task** is completed by one commit carrying **Trailers**.
**Routing** puts a request on a **Path**, and an **Upgrade** or **Downgrade** moves it to another.
The **Check** runs the **Cooldown** and then the **Check target**.
