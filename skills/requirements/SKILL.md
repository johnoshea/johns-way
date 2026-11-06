---
name: requirements
description: Requirements gathering for medium and full work. The purpose first, written back for the user to correct. Then rounds of questions with a recommended answer each, asking only what would change the design. Consult before designing a change to an interface, a second module, or persisted data, or anything new.
---

# Requirements

The goal is a shared understanding sharp enough to design from, reached in as few rounds as possible.

## Before asking

Read first. Facts are the model's job: the code, the tests, the docs, recent commits, the issue if there is one. Anything answerable by looking is never a question. If a question must wait for a lookup, run the lookup as a background subagent and ask the rest of the round.

Check the request's terms against CONTEXT.md and raise conflicts at once; see the domain-language skill.

## Purpose

The purpose has three parts: the outcome the user is after, who it is for, and how the user will tell it worked. A request is often for a feature. The purpose is what the user will do once the feature exists. Take it from the request, the issue, and the repo.

Write the purpose back in two or three lines at the head of the first round. Mark each line as said or assumed. If an assumed line would change the design, ask about it in that round. The user corrects the purpose while answering. When there are no questions to ask, put the lines at the top of the design message.

When a part is missing and you found nothing about it, ask only the purpose question in the first round. Every other question depends on its answer.

## Rounds

Ask every question whose prerequisites are settled in one numbered round. Give each question a recommended answer as a starting point. The user decides how much detail to give.

After the purpose, ask only about decisions that are expensive to reverse. For everything else, state a default in the design, for the user to correct there. The expensive decisions:

- what persists, and its shape
- what runs concurrently, or must survive a restart
- which external systems are touched
- whether there is more than one kind of user, and how they are told apart
- where it is deployed, and what it must integrate with

When the shape is unclear, open with countable questions: how many kinds of user, how many external systems, how many things that persist, what happens without a user asking.

If no question is settled in a round, draft instead: put two drafts in front of the user, each a one-paragraph description and a list of three to six modules, and ask which is closer and what is wrong with it. People correct a wrong draft faster than they answer abstract questions, and compare two faster than they judge one.

Stop when the design stays the same after a round of answers. After three rounds, list the questions still open and wait. The user answers them, or says to draft with them left open.

## Output

When the user answers a round, only that round's questions are settled. The design message, the spec, and the crit gate are still to come, unless the user names a smaller path.

Medium path: the design as one chat message, as routing describes. Full path: the spec skill, with any open questions carried into the spec's Open questions section.
