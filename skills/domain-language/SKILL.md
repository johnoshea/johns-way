---
name: domain-language
description: Building and keeping the project's vocabulary in CONTEXT.md. Consult whenever a term is discussed or disputed, a class, function, or field with domain meaning is added, or CONTEXT.md is read or edited.
---

# Domain language

`CONTEXT.md` at the repository root is the glossary and only the glossary. It overrides READMEs and comments, which drift. It holds no implementation details, no decisions, and no status.

Adapted from Matt Pocock's domain-modeling skill.

## Format

One entry per term:

    **Order**: a customer's request to buy, from checkout until fulfilled or cancelled.
    _Avoid_: purchase, transaction, basket.

A Relationships section may follow, one line each: "An **Order** holds many **Line items**."

## When

- Create the file when the first term needs recording, never before.
- A new class, enum value, function, or field with domain meaning goes into CONTEXT.md in the same commit that introduces it.
- During requirements and spec writing, check the user's terms against the file. Raise a conflict at once: "CONTEXT.md defines cancellation as X, but you seem to mean Y. Which is it?"
- A vague or overloaded term gets a precise proposal: "Account: do you mean the Customer or the User?"
- When the user states how something works, check that the code agrees, and surface contradictions.
- When you catch yourself coining a name for something, write out what the thing is instead. If the concept needs a name, the name goes into CONTEXT.md first.

## Multiple contexts

A repository with more than one bounded context has a `CONTEXT-MAP.md` at the root listing them, and a `CONTEXT.md` in each context's directory. Create the map when the second context appears.

## Decisions

Decisions are recorded in the spec's Alternatives considered section. There are no ADRs.
