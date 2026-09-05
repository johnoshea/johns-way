# Architecture review examples

These show how a finding should read: name the flag, then show the alternative interface and why it is simpler. Each example is small so the shape is visible. On a real subsystem the same moves apply across modules. Match this register: blunt, specific, every finding tied to a complexity cost, and always show the interface the fix produces.

## Example 1: shallow module and complexity exported to callers

**Before:**

```python
class ReportWriter:
    def __init__(self, path: str) -> None:
        self.path = path
        self._file = None
        self._wrote_header = False

    def open(self) -> None:
        self._file = open(self.path, "w")

    def write_header(self, columns: list[str]) -> None:
        self._file.write(",".join(columns) + "\n")
        self._wrote_header = True

    def write_row(self, values: list[str]) -> None:
        if not self._wrote_header:
            raise RuntimeError("call write_header first")
        self._file.write(",".join(values) + "\n")

    def close(self) -> None:
        self._file.close()


# every caller:
w = ReportWriter("out.csv")
w.open()
w.write_header(["name", "score"])
for r in rows:
    w.write_row([r.name, str(r.score)])
w.close()
```

**Review:**

This class is shallow, and it pushes its complexity onto every caller. The interface has five public methods, an ordering contract (`open` before writing, `write_header` before `write_row`, `close` at the end) that the caller must remember and the class enforces with a runtime error, and manual resource management. What it hides is joining a list with commas and appending a newline. The interface is more complex than the implementation, which is the definition of a shallow module, and the cost lands at every call site, with a class of bugs waiting in the ordering contract: a forgotten `close` leaks a file, a missed `open` is an `AttributeError`. That is cognitive load and change amplification for almost no abstraction in return.

The fix pulls all of that down behind one deep call. The caller has rows and wants a file. Everything else is the module's job.

**Designed twice, the two interfaces side by side:**

```
Before (caller must know):          After (caller must know):
  - construct with a path             - write_csv_report(path, columns, rows)
  - call open()
  - call write_header(columns)
  - call write_row() per row
  - call close()
  - the required ordering
```

**After:**

```python
def write_csv_report(
    path: str, columns: list[str], rows: Iterable[Sequence[str]]
) -> None:
    """Write rows to `path` as CSV with the given header columns."""
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(columns)
        writer.writerows(rows)


# every caller:
write_csv_report("out.csv", ["name", "score"],
                 ([r.name, str(r.score)] for r in rows))
```

The ordering contract is gone because there is no order to get wrong. The file cannot leak because the `with` owns it. The header-before-rows invariant is structural instead of enforced at runtime. Hand-rolled CSV is gone too, which was its own latent bug the moment a value contained a comma. The interface is now far simpler than the implementation: a deep module. If callers need streaming writes over a long-lived handle, the right shape is a context manager, `with open_csv_report(path, columns) as w: w.write(row)`, which keeps the file-cannot-leak property while supporting incremental writes. Still one concept to learn instead of five.

## Example 2: information leakage

**Before:**

```python
# ingest.py
def parse_event(line: str) -> dict:
    parts = line.split("|")
    return {"ts": parts[0], "user": parts[1], "action": parts[2]}

# export.py
def format_event(e: dict) -> str:
    return f"{e['ts']}|{e['user']}|{e['action']}"

# audit.py
def is_login(line: str) -> bool:
    return line.split("|")[2] == "login"
```

**Review:**

The event wire format, pipe-delimited with fields in the order ts, user, action, is a single design decision leaked across three modules. `ingest` knows the delimiter and field order to parse it. `export` knows them to write it. `audit` reaches past both to pull field index 2 straight out of a raw line. That is the information-leakage red flag, and it is the most dangerous kind of dependency because nothing connects these three files in the type system. Change the format, by adding a field, switching to JSON, or reordering, and you must find and fix all three, and `audit`'s `split("|")[2]` will silently return the wrong field rather than fail. That is an unknown unknown sitting in the codebase.

The decision needs exactly one owner. Put the format behind an `Event` type that knows how to parse and serialise itself. Everyone else depends on the type.

**After:**

```python
# event.py: the one place that knows the wire format
@dataclass(frozen=True)
class Event:
    ts: str
    user: str
    action: str

    @classmethod
    def parse(cls, line: str) -> "Event":
        ts, user, action = line.split("|")
        return cls(ts, user, action)

    def serialize(self) -> str:
        return f"{self.ts}|{self.user}|{self.action}"

# audit.py
def is_login(event: Event) -> bool:
    return event.action == "login"
```

The format now lives in one module. `audit` asks for `event.action`, a named field rather than a magic index, so reordering or reformatting cannot silently corrupt it, and switching the wire format to JSON touches `Event.parse` and `serialize` and nothing else. The test for real leakage versus harmless shared knowledge: the format is a decision that will plausibly change, so hiding it pays off. If these three files had merely referenced a fixed ISO-8601 timestamp standard that will never change, centralising it would have added a shallow indirection for no benefit. That is the line.

## Example 3: define errors out of existence by redesign

**Before:**

```python
def get_discount(cart: Cart, code: str | None) -> Decimal:
    if code is None:
        raise NoCodeError()
    promo = lookup_promo(code)        # returns None if not found
    if promo is None:
        raise UnknownCodeError()
    if promo.min_total is not None and cart.total < promo.min_total:
        raise BelowMinimumError()
    return promo.amount

# every call site:
try:
    discount = get_discount(cart, code)
except (NoCodeError, UnknownCodeError, BelowMinimumError):
    discount = Decimal(0)
```

**Review:**

This API has defined three exceptions into existence, and every caller pays for it with the same try/except that maps all three back to "no discount". That is the special-cases-as-complexity smell: the branching exists only because of an API design choice, and it is duplicated at every call site, with the risk that a future caller forgets one of the three and crashes on an ordinary "code did not apply" situation.

Step back and ask what the caller wants: the discount, which is zero when no valid code applies. None of these three conditions is a failure. A missing code, an unknown code, and a below-minimum cart are all "the discount is zero". Redefine the contract to make that the normal, total result, and the special cases vanish.

This works because all three conditions are legitimately normal outcomes. If `lookup_promo` could raise on a database outage, that is a genuine fault and must still propagate. Defining errors out of existence eliminates manufactured special cases by design. It never silences real ones.

**After:**

```python
def get_discount(cart: Cart, code: str | None) -> Decimal:
    """The discount for `cart`; zero if no valid, applicable code is given."""
    if code is None:
        return Decimal(0)
    promo = lookup_promo(code)
    if promo is None or not promo.applies_to(cart):
        return Decimal(0)
    return promo.amount

# every call site:
discount = get_discount(cart, code)
```

The function is now total. It always returns a `Decimal`, so the `Optional` mindset and the three-exception try/except disappear from every caller. The min-total rule moved down into `promo.applies_to(cart)`, where the promo's own applicability logic belongs, instead of being exported as a third exception type. One caveat specific to gradually typed Python: now that callers no longer check, the function must always return a value. There is no compiler to catch a path that falls through to `None`, so the totality has to be real.

## Example 4: pass-through layer

**Before:**

```python
class UserService:
    def __init__(self, repo: UserRepository) -> None:
        self._repo = repo

    def get(self, user_id: int) -> User:
        return self._repo.get(user_id)

    def save(self, user: User) -> None:
        self._repo.save(user)

    def delete(self, user_id: int) -> None:
        self._repo.delete(user_id)

    def all(self) -> list[User]:
        return self._repo.all()
```

**Review:**

Every method on `UserService` is a pass-through. It forwards one to one to `UserRepository` with the same signature and adds nothing. This layer exists without doing any work. It is pure cost: one more class to learn, one more file to open when tracing a call, and a maintenance tax because the two signatures have to move in lockstep forever. The two layers express the same abstraction, so the upper one is a different layer in name only.

There are two honest resolutions, and which one is right depends on a question the code cannot answer on its own:

- **If this layer has no real job,** delete it and let callers depend on `UserRepository` directly.
- **If a service layer is meant to exist,** to enforce invariants, coordinate several repositories, publish events, or handle authorisation, then give it that job. Right now it is an empty promise of a layer.

Keeping it as-is for symmetry or in case it is needed later is a shallow layer justified by speculation. YAGNI applies.

One piece of context settles it: is this service a deliberate boundary? If `UserService` is the public seam other modules code against while the repository is free to churn underneath, a thin forwarding layer is a legitimate boundary. Keep it, and document that intent so the next reader leaves it alone. If it is a layer out of habit, it should gain a responsibility or disappear. That distinction, redundant echo versus real boundary, is the whole call here, and it is the kind of thing to ask about rather than bluff. Tell me which it is.
