# PHP Code Standards

Apply with the project `AGENTS.md` and `md-files-standards.md` (shared
rules); this file adds PHP-only rules. Binding analyzers: `phpcs.xml(.dist)`
(PSR-12 + Slevomat), `phpstan.neon`, `psalm.xml` — obey their severity, do
not restate them.

## 1. File layout

- **1.1** `<?php declare(strict_types=1);` per the repo's opening convention;
  every file ends with one blank line.
- **1.2** One class-like symbol per file; keep the file to that symbol and
  nothing else.
- **1.3** No line over 120 chars — counts the whole line including indentation.
- **1.4** Sort `use` statements (external before internal, alphabetical) and
  keep them in sync: add or remove `use` whenever a class is used or dropped.

## 2. Typing

- **2.1** Type every parameter, property, and return value; never `mixed` except
  at a framework boundary, then narrow it immediately.
- **2.2** PHPDoc only where PHP cannot express the type (generics, shapes like
  `array<int, string>`); never use it to restate a signature.
- **2.3** Compare with `===` / `!==` only, never loose `==`.
- **2.4** Handle null before a non-nullable parameter (`??`, default, early
  return); cast explicitly only when needed (`(int) $model->version`).

## 3. Design

- **3.1** Prefer `final` classes unless inheritance is intended; model domain
  data as immutable value objects.
- **3.2** Use constructor property promotion where supported; avoid magic
  methods; add `#[Override]` to every overridden method.
- **3.3** Member order: constants, properties (public→protected→private), then
  constructor, then methods (public→protected→private), alphabetical within each
  group.
- **3.4** Write self-documenting names; no prose or explanatory comments in
  code.

## 4. Quality

- **4.1** No unused classes, methods, properties, or imports; if an unused
  symbol is intended, suppress with `@psalm-suppress` and drop the suppression
  on first use.
- **4.2** Keep functions pure and deterministic; no reliance on global state.

## 5. Naming

- **5.1** Classes, interfaces, enums: `PascalCase`; methods and properties:
  `camelCase`; constants: `UPPER_SNAKE_CASE`.
- **5.2** Acronyms follow normal word rules (`HttpClient`, not `HTTPClient`).

## 6. Error handling

- **6.1** Throw typed custom exceptions; catch and translate only at boundaries.
- **6.2** Never swallow errors with an empty `catch`; never use exceptions for
  control flow.

## 7. Tests

- **7.1** If tests are requested, follow the existing `tests/` patterns
  (`*Test.php`, PHPUnit) — introduce no new framework.
