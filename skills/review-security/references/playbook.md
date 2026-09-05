# Security review playbook

A detection catalogue. Start from a symptom you can see in the code. Each entry gives what an attacker gains, the principle behind the fix, the fix, and the overcorrection to avoid. Entries are ordered by leverage, matching the priority list in SKILL.md. Each names the CWE ids and the OWASP Top 10:2025 category it falls under, so a finding can cite them. Jump to the flag you are looking at.

## Python calibration

- **The shell is the injection.** `subprocess.run([...])` with an argument list passes arguments as data. `shell=True`, `os.system`, and `os.popen` hand a string to a shell.
- **These deserialise into code.** `pickle`, `marshal`, `shelve`, `jsonpickle`, `yaml.load` with any loader but `SafeLoader`, and `eval`, `exec`, or `__import__` on data from outside. `json` and `yaml.safe_load` are the safe defaults.
- **`assert` is a debugging aid.** Running with `-O` strips every `assert`, so a check written as one silently disappears.
- **`random` is predictable.** Tokens, session ids, reset codes, and salts come from `secrets`. Passwords are hashed with argon2, bcrypt, or scrypt, never with a plain digest. Secrets are compared with `hmac.compare_digest`.
- **`os.path.join` discards everything before an absolute component.** `os.path.join(base, "/etc/passwd")` is `/etc/passwd`, and `..` passes through untouched. Resolve with `Path.resolve()` and check `is_relative_to(base)` against a resolved base.
- **`tempfile.mktemp` is a race.** `mkstemp`, `NamedTemporaryFile`, and `TemporaryDirectory` create the file atomically.
- **TLS verification is a flag.** `verify=False` in `requests`, `ssl._create_unverified_context()`, and `check_hostname = False` turn it off.
- **Templates escape only where the framework says so.** A plain Jinja2 `Environment` has autoescape off. Flask turns it on for templates with HTML and XML file extensions. `|safe`, `Markup()`, and `mark_safe()` opt out. Rendering a user-supplied string as a template is code execution.
- **XML parsers resolve entities.** `defusedxml` replaces the standard library parsers for untrusted XML.
- **Type hints do not validate.** A parameter annotated `int` accepts a string at runtime. Validation at the boundary uses a schema library or explicit checks.
- **Framework settings to read first.** Django: `DEBUG`, `SECRET_KEY`, `ALLOWED_HOSTS`, the `CSRF_*` and `SESSION_COOKIE_*` settings. Flask: `SECRET_KEY`, `debug`, the session cookie settings. Both: the CORS configuration.

## Contents

1. [Missing or incorrect authorisation](#1-missing-or-incorrect-authorisation)
2. [Authentication that can be bypassed](#2-authentication-that-can-be-bypassed)
3. [Injection into queries, commands, and code](#3-injection-into-queries-commands-and-code)
4. [Injection into web output](#4-injection-into-web-output)
5. [Path traversal and file handling](#5-path-traversal-and-file-handling)
6. [Deserialisation of untrusted data](#6-deserialisation-of-untrusted-data)
7. [Server-side request forgery](#7-server-side-request-forgery)
8. [Confused deputy and backflow of trust](#8-confused-deputy-and-backflow-of-trust)
9. [Secrets and sensitive data exposure](#9-secrets-and-sensitive-data-exposure)
10. [Cryptographic failures](#10-cryptographic-failures)
11. [Fail open and silent catch](#11-fail-open-and-silent-catch)
12. [Unbounded resource use](#12-unbounded-resource-use)
13. [Input validation at the boundary](#13-input-validation-at-the-boundary)
14. [Insecure defaults and configuration](#14-insecure-defaults-and-configuration)
15. [Predictability](#15-predictability)
16. [Races between check and use](#16-races-between-check-and-use)
17. [Dependencies and supply chain](#17-dependencies-and-supply-chain)
18. [Missing audit](#18-missing-audit)

## 1. Missing or incorrect authorisation

CWE-862, CWE-863, CWE-284, CWE-639. OWASP A01 Broken Access Control.

**Symptom.** A handler or function acts on a resource without checking that the caller may. Checks present in some handlers and absent in others. An object id taken from the request and used directly, so any authenticated user can read or change any object. Authorisation enforced in the UI or the client only. A role or tenant id read from a client-supplied claim, header, or field. Admin functions distinguished only by an obscure URL.

**Gain.** Elevation of privilege, then disclosure or tampering of whatever the missing check guarded. This is the top category in the OWASP Top 10:2025 and appears in nearly every application tested.

**Principle.** Complete mediation: every access to every object is checked for authority. Fail-safe defaults: access rests on permission, never on the absence of a rule.

**Fix.** One place that decides, keyed on the authenticated principal and the object, applied by construction rather than by remembering: a decorator on every handler, a query scoped to the principal in the data access layer, or a service method that takes the principal as a parameter. Deny by default. Object ids resolve through the principal's scope, so an id outside it does not resolve.

**Overcorrection.** Authorisation checks scattered through every function breed gaps and drift. Centralise the decision and make the safe path the only path.

Related: authentication, confused deputy.

## 2. Authentication that can be bypassed

CWE-306, CWE-287. OWASP A07 Authentication Failures.

**Symptom.** A critical function reachable without authentication: an internal endpoint, a debug route, a message consumer that trusts the sender. Tokens compared with `==`. Session ids, reset codes, or API keys that are short, sequential, or derived from user data. Passwords stored with a fast hash. Reset tokens that are reusable or never expire. Login without rate limiting. A session that survives a password change or logout.

**Gain.** Spoofing: the attacker is someone else.

**Principle.** Authentication is the first term of the Gold Standard: a high-assurance determination of the identity of a principal. Avoid predictability.

**Fix.** The framework's authentication, applied to every route by default with explicit opt-out for public ones. `secrets` for every token, `hmac.compare_digest` for every comparison, argon2, bcrypt, or scrypt for passwords. Tokens single-use and short-lived. Sessions invalidated on password change.

**Overcorrection.** Homemade authentication to do it properly. The framework's has been attacked more than yours ever will be.

Related: missing authorisation, predictability, cryptography.

## 3. Injection into queries, commands, and code

CWE-89, CWE-78, CWE-77, CWE-94, CWE-1336. OWASP A05 Injection.

**Symptom.** SQL built by string formatting, f-strings, or concatenation, including in an ORM's raw-query escape hatch. A query for a document store built from request fields. `subprocess` with `shell=True`, `os.system`, or a command string that includes user data. `eval`, `exec`, or `__import__` on anything from outside. A user-supplied string rendered as a template. LDAP filters, XPath, or log lines built the same way.

**Gain.** Elevation of privilege up to code execution, and everything that follows from it.

**Principle.** Untrusted data is data. It never becomes part of the program.

**Fix.** Parameterised queries, always. Argument lists for subprocesses, with no shell. Dynamic identifiers, such as a column to sort by, chosen from an allowlist rather than passed through. Templates take user data as variables. Nothing from outside reaches `eval`.

**Overcorrection.** Escaping or sanitising input instead of parameterising. Escaping is a blocklist, and blocklists leak.

Related: web output, deserialisation, input validation.

## 4. Injection into web output

CWE-79, CWE-352. OWASP A05 Injection, A01 Broken Access Control.

**Symptom.** Autoescape off. `|safe`, `Markup()`, or `mark_safe()` applied to user data. HTML or JavaScript built by string concatenation. User data inside a script block, an attribute, a URL, or an inline event handler. A state-changing request served on GET. Forms without CSRF tokens. Session cookies without `SameSite`, `HttpOnly`, or `Secure`.

**Gain.** Cross-site scripting runs the attacker's script as the user, which is spoofing and tampering with everything the user can do. Cross-site request forgery makes the user's browser act for the attacker.

**Principle.** Encode output for the context it lands in. A state change needs proof the user intended it.

**Fix.** Autoescape on everywhere, and `|safe` only on content the server built. Data for scripts passed as JSON in a data attribute rather than interpolated. The framework's CSRF protection on every state-changing route. `SameSite=Lax` or stricter on session cookies. A Content Security Policy as defence in depth.

**Overcorrection.** Stripping tags from input on the way in. Encoding belongs at output, for the context, and input filtering breaks legitimate data.

Related: injection into queries, insecure defaults.

## 5. Path traversal and file handling

CWE-22, CWE-434. OWASP A01 Broken Access Control, A06 Insecure Design.

**Symptom.** A path built from a request value, where the value can contain `..` or be absolute. A filename taken from an upload and used as-is. A file type judged by extension or by the client's content type. Archives extracted without checking each member's resolved path. Files served from a directory by user-supplied name. Symlinks followed inside a user-writable tree.

**Gain.** Disclosure of any file the process can read, tampering with any it can write, and code execution when the written file is later executed or served.

**Principle.** Canonicalise, then check against an allowlist.

**Fix.** Resolve the full path and require it to be inside the resolved base directory. Generate storage names on the server and keep the client's name as metadata. Check content rather than extension, and store uploads outside the web root and outside any executable path. Extract archives member by member with the same resolved-path check.

**Overcorrection.** Blocklisting `..`. Encodings, symlinks, and absolute paths get past it.

Related: injection, input validation.

## 6. Deserialisation of untrusted data

CWE-502, CWE-611. OWASP A08 Software or Data Integrity Failures, A02 Security Misconfiguration.

**Symptom.** `pickle`, `marshal`, `shelve`, `jsonpickle`, or `yaml.load` with a loader other than `SafeLoader` on data that crossed a trust boundary: a request body, a queue message, a cache entry another service can write, an uploaded file. XML parsed by the standard library with external entities on. Objects rebuilt from a class name carried in the data. A signed or encrypted blob deserialised before the signature is checked.

**Gain.** Code execution in the deserialising process.

**Principle.** Reluctance to trust: trust is an explicit choice backed by evidence. A data format carries data.

**Fix.** JSON, or another data-only format, validated against a schema at the boundary. `yaml.safe_load`. `defusedxml`. Verify the signature before parsing anything. When `pickle` between trusted processes is unavoidable, sign the payload and check it first.

**Overcorrection.** A blocklist of dangerous classes for the unpickler. Bypasses are published regularly.

Related: injection, input validation, confused deputy.

## 7. Server-side request forgery

CWE-918. OWASP A01 Broken Access Control.

**Symptom.** The server fetches a URL that came from a request: a webhook target, an image to proxy, an import-from-URL feature, a link preview, a discovery endpoint. Redirects followed without re-checking the destination. DNS resolved once for the check and again for the connection. Cloud metadata endpoints reachable from the process.

**Gain.** The attacker uses the server's network position and credentials: internal services, metadata endpoints that hand out cloud credentials, and anything behind the firewall.

**Principle.** Allowlists over blocklists. Least privilege for the process's network access.

**Fix.** An allowlist of schemes and hosts when the set is known. When it is open, resolve the host, reject private, loopback, link-local, and metadata ranges, connect to the resolved address, and refuse redirects to a host that fails the same check. Block the metadata endpoint at the network level as well.

**Overcorrection.** A blocklist of strings such as `localhost`. Encodings, IPv6, and DNS rebinding get past it.

Related: input validation, confused deputy.

## 8. Confused deputy and backflow of trust

CWE-441. OWASP A01 Broken Access Control.

**Symptom.** A privileged service performs an action for a less privileged caller using its own authority, without carrying the caller's identity through, so a check that would have failed for the caller passes for the service. A background job that acts on ids from a queue anyone can write to. A lower-trust component that directs a higher-trust one: a client that tells the server which user it is, a plugin that drives its host, a build script that deploys, a third-party hook with broad access.

**Gain.** Elevation of privilege to whatever the deputy holds.

**Principle.** Keep the request context through the whole task so authorisation can be checked as the original caller. A component that a lower-trust component controls has the lower trust in practice.

**Fix.** Pass the principal through every layer and authorise at the point of action as that principal. Authenticate queue messages and job requests. Restrict hooks and plugins to the narrow function they need.

**Overcorrection.** Re-authenticating the user at every layer. Carry the authenticated context and check authorisation where the action happens.

Related: missing authorisation, dependencies.

## 9. Secrets and sensitive data exposure

CWE-200, CWE-798, CWE-532, CWE-209. OWASP A01 Broken Access Control, A07 Authentication Failures, A09 Security Logging and Alerting Failures, A10 Mishandling of Exceptional Conditions.

**Symptom.** Credentials, keys, or tokens in source, in committed configuration, in a container image, or in a default value. Secrets in log lines, exception messages, stack traces returned to clients, URLs, or query strings. Debug mode or verbose errors in production. Whole records passed where one field was needed, so a callee or a log sees more than it should. Personal data kept without a reason. Sensitive data in client-side storage or in a cache another tenant can read.

**Gain.** Disclosure, and every disclosed secret is spoofing waiting to happen.

**Principle.** Least information: provide only the private information a call needs. Open design: security rests on the key, never on the code staying secret.

**Fix.** Secrets from the environment or a secret manager, never from the repository. Error responses that say what the client needs, with the rest logged server-side. Redaction in the logging layer, by construction. Narrow data contracts: pass the fields, not the record. Delete what is no longer needed.

**Overcorrection.** Encrypting everything at the application layer so the key becomes the new secret in code. Fix where the secret lives first.

Related: cryptography, audit, insecure defaults.

## 10. Cryptographic failures

CWE-327, CWE-330, CWE-338. OWASP A04 Cryptographic Failures.

**Symptom.** A homemade algorithm, protocol, or mode of operation. MD5 or SHA-1 for anything but checksums. A fast hash for passwords. `random` for keys, tokens, IVs, or salts. A fixed IV or nonce. ECB mode. Encryption without authentication. A key derived from a password without a proper key derivation function. TLS verification off, or a private CA trusted everywhere. Keys hardcoded, shared across environments, or never rotated.

**Gain.** Disclosure of what the cryptography protected, and tampering with it when there is no authentication.

**Principle.** Open design. Avoid predictability. Use the recipes.

**Fix.** The `cryptography` package's high-level recipes: Fernet, or AES-GCM with a fresh nonce per message. `secrets` for every random value. argon2 or bcrypt for passwords. TLS verified. Keys from a secret manager, one per environment, rotated.

**Overcorrection.** Bluffing about a protocol or a primitive. When the review cannot verify a construction, say what would need checking rather than passing or failing it.

Related: predictability, secrets exposure.

## 11. Fail open and silent catch

CWE-755, CWE-636. OWASP A10 Mishandling of Exceptional Conditions.

**Symptom.** A broad `except` that passes, or logs and continues, around a security check, a signature verification, or a permission lookup. A check that returns `None` on error and a caller that treats anything but `False` as a pass. `assert` used to enforce a condition. A remote authorisation service that is unavailable and a fallback that allows. A partial write left in place after a failure. Cleanup that runs only on the success path.

**Gain.** Whatever the skipped check guarded. Error paths are fertile ground because they are the least tested code in the system.

**Principle.** Fail securely: an error leaves the system in a secure state. Fail-safe defaults.

**Fix.** A security check that cannot complete denies. The check's failure is the caller's failure: raise, never return a value the caller can misread. Transactions or atomic writes so a failure leaves nothing half done. Cleanup in `finally` or a context manager. Tests for the error paths.

**Overcorrection.** Treating every broad `except` as a finding. The finding is a broad `except` around a check that matters.

Related: unbounded resource use, missing authorisation.

## 12. Unbounded resource use

CWE-770, CWE-400, CWE-1333.

**Symptom.** A request body, upload, or file read fully into memory with no size limit. No limit on the length of a list, the depth of nesting, the number of items in a batch, or the size of a page. A regular expression with nested quantifiers applied to user input. Recursion driven by input. Outbound calls without a timeout. Queues, caches, or per-user storage without a cap. Expensive work done before authentication or before a cheap check that would have rejected the request.

**Gain.** Denial of service, often from a single request.

**Principle.** Economy of mechanism. Every place untrusted input sets a size or a count has a limit.

**Fix.** Limits at the boundary: body size, item count, nesting depth, page size. Timeouts on every outbound call. Streaming instead of reading whole. Simple regular expressions. Cheap checks before expensive work. Rate limits per principal.

**Overcorrection.** Limits so tight they become an availability bug. Set them from real usage plus margin, and make them configuration.

Related: fail open, input validation.

## 13. Input validation at the boundary

CWE-20, CWE-915. OWASP A05 Injection, A08 Software or Data Integrity Failures.

**Symptom.** Validation in some entry points and absent in others. Validation on the client only. A blocklist of bad values. Request fields written straight to a model, including ones the user may never set. Values used before they are checked. Types assumed from a hint rather than enforced. Data validated on write and trusted on read when another writer exists.

**Gain.** Depends on the sink, which is why this entry is the root of most of the ones above.

**Principle.** Allowlists over blocklists. Accept security responsibility: the boundary owns validation, and both sides of an interface agree who checks what.

**Fix.** Validate once, at the trust boundary, into typed values with an allowlist of what is accepted. Reject rather than repair. Explicit field lists for anything written to a model. Everything inside the boundary works on validated types and never re-parses the raw request.

**Overcorrection.** Validating the same value in every layer as a substitute for a boundary. Defence in depth adds an independent check at a second boundary; it does not scatter the first.

Related: every injection entry, deserialisation.

## 14. Insecure defaults and configuration

CWE-1188, CWE-942, CWE-732. OWASP A02 Security Misconfiguration, A01 Broken Access Control.

**Symptom.** Debug on, or switchable by an environment variable that defaults on. Cross-origin requests allowed from any origin with credentials. A server bound to all interfaces by default. World-readable or world-writable files created by the application. Default credentials. TLS optional. Security headers absent. A flag that disables a check, added for a test or a migration and never removed. Configuration that must be changed after deployment to be safe.

**Gain.** Whatever the default exposes. Misconfiguration is the second category in the OWASP Top 10:2025 and was found in every application tested.

**Principle.** Secure by default: the software is secure as deployed, and the operator loosens it explicitly.

**Fix.** Restrictive defaults in code, with permissive settings requiring a named, explicit choice. Debug off unless a development flag is set. Restrictive file modes on creation. An allowlist of origins. The disabling flag removed when the reason for it is gone.

**Overcorrection.** Hardening the configuration of an environment the code does not own. Report it separately.

Related: dependencies, secrets exposure.

## 15. Predictability

CWE-330, CWE-340, CWE-377. OWASP A04 Cryptographic Failures, A01 Broken Access Control.

**Symptom.** Sequential or timestamp-based ids exposed to users. Tokens, codes, or filenames from `random`, from a hash of user data, or from a counter. Temporary files with guessable names in a shared directory. Responses or timing that reveal whether an account exists.

**Gain.** Disclosure by guessing, and tampering when a guessed id names something writable.

**Principle.** Avoid predictability: anything predictable cannot be kept private.

**Fix.** `secrets.token_urlsafe` for tokens, a random id for anything exposed, `tempfile.mkstemp` or `NamedTemporaryFile` for temporary files. Constant-time comparison and uniform responses where existence is sensitive.

**Overcorrection.** Random ids for internal keys that are never exposed. The fix goes where the id crosses a boundary.

Related: authentication, cryptography.

## 16. Races between check and use

CWE-367, CWE-362. OWASP A06 Insecure Design.

**Symptom.** A check followed by an action on the same file, record, or balance with no lock or transaction between them. A balance read, compared, then debited. A file checked for existence or permissions, then opened. A temporary file created by name, then written. A one-time token checked, then marked used, in two statements.

**Gain.** Tampering: the attacker changes the thing between the check and the use, or uses it twice.

**Principle.** Complete mediation applies at the instant of use.

**Fix.** Atomic operations: a single statement that checks and acts, a transaction at an isolation level that prevents the race, `open` in `x` mode, a compare-and-swap. Act, then check what the action reported.

**Overcorrection.** Locks everywhere. Find the invariant the race breaks and protect that one.

Related: fail open, predictability.

## 17. Dependencies and supply chain

CWE-1104, CWE-829. OWASP A03 Software Supply Chain Failures, A08 Software or Data Integrity Failures.

**Symptom.** No lockfile, or one that deployment ignores. Packages installed from arbitrary URLs, from an unverified mirror, or at runtime by the application itself. A dependency pinned years back because upgrading broke something. Binary-only components, vendored copies with no upstream, or anything the team could not update within a day. A build or deploy step that runs code from a source it does not control. An auto-update mechanism with broader access than downloading and installing.

**Gain.** Code execution with whatever the build, deploy, or runtime holds.

**Principle.** An unpatchable component is a permanent vulnerability. A third-party hook gets the narrowest function that works.

**Fix.** A lockfile that deployment honours, and the dependencies skill's cooldown. Nothing the team cannot update quickly. Hooks and update mechanisms restricted to the one function they need. Scanners handle known vulnerable versions; the review looks at the shape.

**Overcorrection.** Listing every outdated package. That is a scanner's job. The finding is a dependency that cannot be updated or a path that runs uncontrolled code.

Related: insecure defaults, confused deputy.

## 18. Missing audit

CWE-778. OWASP A09 Security Logging and Alerting Failures.

**Symptom.** Login, logout, privilege changes, payments, deletions, exports, and admin actions recorded without the principal, the target, the time, or the outcome, or not recorded at all. Logs the acting user can alter or delete. Failed attempts unrecorded, so an attack in progress is invisible. Logs that contain the secrets they are meant to protect.

**Gain.** Repudiation: an actor denies an action and nothing proves otherwise. Every other attack becomes harder to detect and reconstruct.

**Principle.** Auditing, the third term of the Gold Standard: a reliable record of actions by principals for inspection.

**Fix.** One audit call at the point of every security-relevant action, recording who, what, which object, when, and the result, to a store the actor cannot alter. Redaction by construction, so the audit trail is not itself a leak.

**Overcorrection.** Logging everything at debug level and calling it audit. Audit is a small set of events, complete and tamper-resistant.

Related: secrets exposure.
