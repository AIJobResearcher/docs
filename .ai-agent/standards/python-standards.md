# Python Code Standards

Apply with the project `AGENTS.md` and `md-files-standards.md` (shared
rules); this file adds Python-only rules. The formatter, linter and type
checker configured in `pyproject.toml` are binding. Default to
object-oriented design — §2.

## 1. Types

- **1.1** Annotate every public function, domain interface and non-obvious
  value; add `from __future__ import annotations` when the Python version
  needs it.
- **1.2** No `Any` outside an external boundary; narrow it immediately.
- **1.3** No mutable default arguments — default to `None`, build inside.

## 2. Design

- **2.1** Keep behavior on the object that owns the data: invariants and
  intention-revealing methods, never an anemic holder with logic elsewhere.
- **2.2** Encapsulate state — private attributes, no public setters; a mutator
  validates before anything changes.
- **2.3** One responsibility per class and file; split anything mixing domain,
  I/O and framework code.
- **2.4** Compose, do not inherit: is-a only, at most two levels deep, and a
  `Protocol` or ABC — not a base class — for a shared contract.
- **2.5** Declare a `Protocol` or ABC per port and inject it through
  `__init__`; never import an adapter or a global into business logic.
- **2.6** `__init__` assigns fields only — no I/O or heavy work; alternate
  instances come from a `@classmethod` factory.
- **2.7** Value objects are immutable (`@dataclass(frozen=True)`); a pure
  operation returns a new value.
- **2.8** No `@property` for a plain get/set pair; no `isinstance` branch where
  polymorphism fits.

## 3. FastAPI and data

- **3.1** Validate every request with Pydantic at the boundary, before
  business logic.
- **3.2** I/O-bound handlers are `async def`; long work is a Celery task, never
  inside the request.
- **3.3** Keep FastAPI, Celery, ORM and broker code out of the domain layer
  (2.5).

## 4. Async and queue

- **4.1** Make every Celery task and consumer idempotent and retry-safe; assume
  at-least-once delivery.
- **4.2** Propagate correlation and causation ids through chains and messages;
  log them structurally.

## 5. Imports and packaging

- **5.1** Order imports stdlib → third-party → local; import explicit names,
  never wildcards.
- **5.2** Keep import-time code side-effect free and module state immutable.
- **5.3** Declare every dependency in `pyproject.toml`; add a library only for
  what the standard library lacks, and never import or install an undeclared
  package.
- **5.4** Import only from the packaged source tree — never from `tests/` or
  scripts.
- **5.5** Change the schema only through Alembic migrations; never by hand.

## 6. Style

- **6.1** Leave layout to the formatter and linter; add no rule duplicating
  them.
- **6.2** `snake_case` functions, variables and modules; `PascalCase` classes;
  `UPPER_SNAKE_CASE` constants; `_` for private members.
- **6.3** Docstring on every public module, class, function and method: one
  imperative line ending in a period; args, returns and raises only when the
  signature hides them.
- **6.4** Comments explain why; fix or delete a stale one.
- **6.5** f-strings only; join repeated output with `"".join`, never `+=`.
- **6.6** Keep functions single-purpose; make extra arguments keyword-only.

## 7. Errors

- **7.1** Raise and catch typed exceptions; never a bare `except:`; preserve
  the cause with `raise ... from`.
- **7.2** Open every resource in a `with` block; never swallow an error.
- **7.3** Never validate with `assert` — it is dropped under `-O`.

## 8. Tests

- **8.1** Follow existing `tests/` patterns (`test_*`, pytest); introduce no
  new framework.
- **8.2** Levels and priority (Domain → Application → Integration →
  Acceptance) — `testing-standards.md`.
