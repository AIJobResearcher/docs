# Python Code Standards

Apply with the project `AGENTS.md` and `md-files-standards.md` (shared
rules); this file adds Python-only rules. Binding tools: the formatter,
linter, and type checker configured in `pyproject.toml`.

## 1. Types

- **1.1** Annotate every public function, domain interface, and non-obvious
  value; add `from __future__ import annotations` where the repo or supported
  Python version requires it.
- **1.2** Avoid `Any`; allow it only at an external or dynamic boundary and
  narrow it immediately.
- **1.3** Never use mutable default arguments — default to `None` and build the
  object inside the function.

## 2. FastAPI and data

- **2.1** Model DTOs and API schemas with Pydantic and validate at the FastAPI
  boundary before any business logic runs.
- **2.2** Use `async def` for I/O-bound handlers; run long work as Celery tasks,
  never inside the request handler.
- **2.3** Keep FastAPI, Celery, ORM, and broker concerns out of the domain
  layer; use dependency injection, not module globals.

## 3. Imports and DB

- **3.1** Sort imports stdlib → third-party → local; remove unused ones.
- **3.2** Change the database schema only through Alembic migrations; never
  alter it manually or from runtime code.

## 4. Async and queue

- **4.1** Make every Celery task and event consumer idempotent and retry-safe;
  never rely on exactly-once delivery.
- **4.2** Propagate correlation and causation identifiers through Celery chains
  and consumed messages, and log them in structured form.

## 5. Naming

- **5.1** Functions, variables, modules: `snake_case`; classes: `PascalCase`;
  constants: `UPPER_SNAKE_CASE`; private members prefixed with `_`.

## 6. Error handling

- **6.1** Raise and catch typed exceptions; never a bare `except:`.
- **6.2** Close resources with context managers (`with`); never swallow errors
  silently.

## 7. Tests

- **7.1** If tests are requested, follow existing `tests/` patterns (`test_*`,
  pytest) — introduce no new framework.
