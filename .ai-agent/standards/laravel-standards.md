# Laravel Code Standards

Apply with the project `AGENTS.md`, `md-files-standards.md`, and
`php-standards.md`; this file adds Laravel-specific rules.

## 1. Layering

- **1.1** Dependency direction: Presentation → Application → Domain; Domain
  never depends on Infrastructure (Eloquent, HTTP, queues).
- **1.2** Controllers and Eloquent models stay thin; orchestration lives in
  service/action classes, persistence hides behind repositories that return
  domain aggregates, never query builders or models.

## 2. Eloquent and data

- **2.1** Access data through Eloquent or the Query Builder; allow raw SQL only
  when explicitly justified and always parameterized.
- **2.2** Change schema only through migrations; never alter it manually or from
  application code.
- **2.3** Add `@property` / `@property-read` for magic properties and type-hint
  relations where needed.
- **2.4** In repository queries test relation existence with an explicit
  `JOIN` + `->exists()` (two queries, or `UNION ALL` to cut round-trips);
  avoid `whereHas`, `LEFT/RIGHT JOIN IS NOT NULL`, or loading models to
  check a relation.

## 3. Input and dependencies

- **3.1** Validate all input at the boundary with Form Request rules; never
  trust client-supplied data.
- **3.2** Resolve collaborators by constructor injection through the service
  container; no facades or globals in service and domain code.

## 4. Async and logging

- **4.1** Move slow or recurring work into idempotent, retry-safe queued jobs;
  never publish integration events fire-and-forget from a controller — dispatch
  them through the transactional Outbox tied to the committing transaction.
- **4.2** Log centrally as structured JSON with a correlation ID from the
  request or event; never log secrets.

## 5. Naming

- **5.1** Models and classes: `PascalCase`; methods: `camelCase`; DB tables:
  `snake_case` plural; pivot tables name both models alphabetically.

## 6. Tests

- **6.1** If tests are requested, follow existing `tests/` patterns
  (`*Test.php`, PHPUnit, Feature/Unit) — introduce no new framework.
