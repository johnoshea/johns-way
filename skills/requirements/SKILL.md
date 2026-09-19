---
name: requirements
description: Requirements gathering for medium and full work. The purpose first, written back for the user to correct. Then rounds of questions with a recommended answer each, asking only what would change the design. Consult before designing anything that touches an interface, a second module, or persisted data, or that is new.
---

# Requirements

The goal is a shared understanding sharp enough to design from, reached in as few rounds as possible.

## Before asking

Read first. Facts are the model's job: the code, the tests, the docs, recent commits, the issue if there is one. Anything answerable by looking is never a question. A lookup that would hold up a question runs as a background subagent while the rest of the round is asked.

Check the request's terms against CONTEXT.md and raise conflicts at once; see the domain-language skill.

## Purpose

The purpose has three parts: the outcome the user is after, who it is for, and how the user will tell it worked. A request often names a feature. The purpose is what the user will do once the feature exists. Take it from the request, the issue, and the repo.

Write the purpose back in two or three lines at the head of the first round. Mark each line as said or assumed. An assumed line that would change the design becomes a question in that round. The user corrects the purpose while answering. When there are no questions to ask, the lines head the design message.

When a part is missing and nothing read supplies it, the first round is the purpose question alone. Every other question depends on its answer.

## Rounds

Ask every question whose prerequisites are settled in one numbered round. Each question carries a recommended answer as a starting point. The user answers in whatever depth the decision needs.

After the purpose, ask only about decisions that are expensive to reverse. Everything else gets a stated default in the design, which the user corrects there. The expensive decisions:

- what persists, and its shape
- what runs concurrently, or must survive a restart
- which external systems are touched
- whether there is more than one kind of user, and how they are told apart
- where it deploys, and what it must integrate with

When the shape is unclear, open with countable questions: how many kinds of user, how many external systems, how many things that persist, what happens without a user asking.

A round that settles nothing is the signal to draft instead: put two drafts in front of the user, each a one-paragraph description and a list of three to six modules, and ask which is closer and what is wrong with it. People correct a wrong draft faster than they answer abstract questions, and compare two faster than they judge one.

Stop when answers stop changing the design. After three rounds, list the questions still open and wait. The user answers them, or says to draft with them left open.

## Output

An answer settles the questions in its round and nothing later. The design message, the spec, and the crit gate still follow, unless the user names a smaller path.

Medium path: the design as one chat message, as routing describes. Full path: the spec skill, with any open questions carried into the spec's Open questions section.
