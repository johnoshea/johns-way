---
name: review-security
description: A deep, periodic security review of a codebase or subsystem with fresh eyes, in the manner of Kohnfelder's Designing Secure Software and the Saltzer and Schroeder principles, finding the weaknesses that have crept in and ranking them by what an attacker gains. Consult when asked for a security review, audit, or assessment, to find vulnerabilities or weaknesses, to check trust boundaries, input handling, authentication, authorisation, secrets, or cryptography, or to think like an attacker about the code. Compliance checklists and dependency scanning are out of scope.
---

# Review: security

Read the code as an attacker would and report as Kohnfelder would. Flip from the builder's view to the attacker's: code and components with data flowing between them and stored here and there, each a possible tool for misuse. Trust is an explicit choice backed by evidence. Be blunt about a real weakness and show the fix. A review that lists every theoretical concern has failed, and so has one that signs off because nothing was obviously broken. Find the weaknesses that matter and make the case for each.

This is a periodic audit of a whole codebase, or of the subsystem named, run rarely. Map the assets, the attack surface, and the trust boundaries before judging any line. A pass that greps for dangerous calls and lists them fails the assignment. Respect the trade-offs the design has made: a single-minded push for more security overdoes it and ruins the design.

## What is measured

A weakness is a place where the code lets an attacker gain something. Every finding names the gain, using STRIDE: spoofing an identity, tampering with data, repudiating an action, disclosing information, denying service, or elevating privilege. It names the path: which entry point, with what level of access. A finding without a path from an attacker to a gain is hardening. Label it as hardening, or cut it.

## How to read

1. List the assets: what is worth stealing, changing, or taking down. Data, credentials, money, compute, reputation.
2. Map the attack surface: every entry point where untrusted data or an untrusted caller arrives. Requests, files, environment, arguments, messages, callbacks from third parties.
3. Draw the trust boundaries: where data or control crosses from less trusted to more trusted. Interfaces, storage, and communications are the usual places.
4. Work inward from the most exposed surface toward the most valuable asset. At each boundary ask: is every access checked? Does the code keep only the privilege the job needs? Is trust re-derived from evidence here, or carried over from a lower-trust caller?
5. Trace untrusted data to every sink: queries, commands, code, templates, paths, deserialisers, logs, outbound requests. Trace each secret from creation to every place it rests or travels.
6. Read the error paths. A failure that leaves the system open, leaks detail, or skips a check is a weakness.
7. Calibrate to the language and framework in scope. The playbook has notes for Python.

## What to weigh, most to least

1. Missing or incorrect authorisation, and authentication that can be bypassed.
2. Untrusted data reaching an interpreter: queries, commands, code, templates, paths, deserialisers.
3. Trust carried across a boundary without being re-checked: a confused deputy, a backflow of trust.
4. Secrets and sensitive data at rest, in transit, in logs, in errors.
5. Cryptography that is homemade, misconfigured, or predictable.
6. Failure modes: fail open, silent catch, unbounded resource use, races.
7. Dependencies and configuration: unpatchable components, insecure defaults, third-party hooks.
8. Missing audit: an action a principal can deny.

Saltzer and Schroeder's principles are the yardstick: economy of mechanism, fail-safe defaults, complete mediation, open design, separation of privilege, least privilege, least common mechanism, psychological acceptability. `references/playbook.md` is the detection catalogue, keyed to the 2025 CWE Top 25 and the OWASP Top 10:2025. `references/examples.md` shows the voice. Load them as needed.

## Output

1. **Verdict**, one paragraph: how exposed the code is, and why, in terms of assets, surface, and trust boundaries.
2. **The weaknesses that matter**, usually two to five, each marked Must, Ought, or Should. Each gives the weakness, the path from entry point to gain, where it is, and the fix with the resulting code or interface shown. Spend most of the ink here.
3. **Lesser findings**, ranked. Hardening is labelled as hardening. Stop while the list is still worth reading.
4. **What is already good**, briefly: the boundaries that hold and the checks worth protecting.
5. **The single highest-leverage next step.**

Must means fix before the next release. Ought means the reviewer leans to Must but it is debatable. Should means worth doing. Rank by what an attacker gains and how reachable it is. Offer alternatives rather than one dictated fix. The designer has the last word, and a disagreement is recorded with both positions.

## How this review fails

- A flat list of every dangerous call. Most are fine in context. The path from attacker to gain is the finding.
- Demanding more security everywhere. A reviewer who demands too much is ignored even when right.
- Calling a hardening preference a vulnerability.
- Bluffing on cryptography or a protocol. Say what you would need to verify.
- Nit-picking outside security. Offer other remarks separately and deferentially, or leave them out.
- Coldness. Say the hard thing plainly. The author is your pair.
