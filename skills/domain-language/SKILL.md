---
name: domain-language
description: Building and keeping the project's vocabulary in CONTEXT.md. Consult whenever a term is discussed or disputed, a class, function, or field with domain meaning is added, or CONTEXT.md is read or edited.
---

# Domain language

`CONTEXT.md` at the repository root is the glossary and only the glossary. Where it conflicts with a README or a comment, CONTEXT.md is correct, because READMEs and comments go out of date. It contains no implementation details, no decisions, and no status.

Adapted from Matt Pocock's domain-modeling skill.

## Format

One entry per term:

    **Order**: a customer's request to buy, from checkout until fulfilled or cancelled.
    _Avoid_: purchase, transaction, basket.

After the entries, you may add a Relationships section, one line each, with a state verb such as has, is, or contains: "An **Order** has many **Line items**."

## When

- Create the file when there is a first term to record, never before.
- Add each new class, enum value, function, or field with domain meaning to CONTEXT.md in the same commit as the code.
- During requirements and spec writing, check the user's terms against the file. Raise a conflict at once: "In CONTEXT.md, cancellation is X, but you seem to mean Y. Which is it?"
- For a vague or overloaded term, propose a precise one: "Account: do you mean the Customer or the User?"
- When the user states how something works, check the code for the same behaviour, and report any contradiction.
- When you catch yourself coining a name for something, write out what the thing is instead. If the concept needs a name, add the name to CONTEXT.md first.

## Multiple contexts

A repository with more than one bounded context has a `CONTEXT-MAP.md` at the root with a list of them, and a `CONTEXT.md` in each context's directory. Create the map when you add the second context.

## Decisions

Decisions are recorded in the spec's Alternatives considered section. There are no ADRs.
