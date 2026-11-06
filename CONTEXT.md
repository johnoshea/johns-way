# Glossary

**Path**: the size class a request is worked on, one of small, medium, full, or spike, each with its own process.
_Avoid_: tier, mode, track, level.

**Routing**: classifying a request onto a path before work starts.
_Avoid_: triage, sizing.

**Upgrade**: moving a request to a larger path mid-task, on one of three named triggers and with the user's confirmation.
_Avoid_: escalate, promote.

**Downgrade**: moving a request to a smaller path mid-task, at once and without asking.
_Avoid_: de-escalate, demote.

**Purpose**: the outcome the user is after, who it is for, and how the user will tell it worked.
_Avoid_: intent, goal, motivation.

**Spec**: the one file per full-path feature, under `docs/specs/`, holding the design and its ordered task list.
_Avoid_: plan, design doc, RFC.

**Task**: one numbered line under a spec's Tasks heading, completed by exactly one commit.
_Avoid_: step, ticket, story.

**Trailer**: a Spec line and a Task line at the end of a commit message, for the spec and the task completed by the commit.
_Avoid_: tag, footer, label.

**Amendment**: a dated entry in a spec recording a change made during implementation and why.
_Avoid_: revision, edit, changelog.

**Check target**: the command a project runs to test and lint itself, found in its justfile or pyproject.toml.
_Avoid_: check command, check recipe, test suite.

**Check**: what every commit must pass, the dependency cooldown and then the check target.
_Avoid_: pre-commit, validation, gate.

**Cooldown**: the rule that a dependency version is adopted only once it is 14 days old.
_Avoid_: quarantine, embargo, waiting period.

**Session check-in**: the one message per session, after a time limit, with the question of whether to upgrade medium work to full.
_Avoid_: reminder, timer, nudge.

**Gate**: a point where work stops and waits for the user: the crit round on a spec, the crit round on the review findings, and any question asked with AskUserQuestion. The gate hook blocks tool calls while a gate is open.
_Avoid_: checkpoint, approval, sign-off.

**Definition of done**: running the check target, pasting its real output, updating README.md, CLAUDE.md, and CONTEXT.md to match what the code now does, and writing a plain-language commit message: a subject with the change to the files, and a body with the reason.
_Avoid_: done criteria, acceptance, DoD.

**Reviewer**: the plugin's subagent that reviews a finished change with fresh context, against its spec and the design rules.
_Avoid_: critic, auditor, second opinion.

**Cold reader**: a subagent given a draft, a commit message with its staged diff or a reply, with no session context, that reports what it cannot resolve from that alone.
_Avoid_: fresh reader, stranger, second pair of eyes.

**Deletion test**: imagining a module or a test deleted and naming what is lost: complexity that must be repeated in its callers, or a defect that is no longer caught.
_Avoid_: removal check, ablation.

**Vacuous test**: a test that would pass with any plausible defect in the code under test, or that fails only on a defect another test already catches.
_Avoid_: trivial test, redundant test, weak test, useless test.

**Local install**: the development checkout linked into Claude Code and copied into a generated Codex marketplace, refreshed with `just install`.
_Avoid_: deployment, release.

## Relationships

A **Spec** contains many **Tasks**, and each **Task** is completed by one commit with **Trailers**.
A **Spec**'s Problem paragraph contains the **Purpose**.
Each request is on one **Path**. Claude chooses it during **Routing**, and changes it with an **Upgrade** or a **Downgrade**.
The **Check** is the **Cooldown** followed by the **Check target**.
