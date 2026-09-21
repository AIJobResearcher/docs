# Laravel Code Standards

Apply with the project `AGENTS.md`, `md-files-standards.md`, and
`php-standards.md`; this file adds Laravel-specific rules.

## 1. Layering

- **1.1** Dependency direction: Presentation → Application → Domain; Domain
  never depends on Infrastructure (Eloquent, HTTP, queues).
- **1.2** Controllers and Eloquent models stay thin; orchestration lives in
  service/action classes, persistence hides behind repositories that return
  domain aggregates, never query builders or models.
- **1.3** HTTP-to-DTO mapping stays in Presentation; Application never imports
  Illuminate HTTP request types.
- **1.4** Domain code never traverses relations across aggregate roots; a
  missing read field becomes a repository method.

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

- **3.1** Validate all input at the boundary with Form Request rules;
  validation lives only there — route constraints such as `whereUuid` do not
  validate parameters; never trust client-supplied data.
- **3.2** Resolve collaborators by constructor injection through the service
  container; no facades or globals in service and domain code.

## 4. HTTP layer

- **4.1** New endpoint checklist, in order: route → FormRequest (validation
  only) → DTO or named accessor → UseCase → repository method → JsonResource
  → thin controller → permissions → runtime verification.
- **4.2** Use cases expose a named entry method `handle(...)`, never
  `__invoke`.
- **4.3** A route with a single path value uses a named FormRequest accessor,
  not a DTO.
- **4.4** One JsonResource per route; nested resource classes only where the
  schema nests objects.
- **4.5** A response matches its OpenAPI section exactly — no undocumented
  members such as `links`, `X-Total-Count`, or extra meta keys.

## 5. Async and logging

- **5.1** Move slow or recurring work into idempotent, retry-safe queued jobs;
  never publish integration events fire-and-forget from a controller — dispatch
  them through the transactional Outbox tied to the committing transaction.
- **5.2** Log centrally as structured JSON with a correlation ID from the
  request or event; never log secrets.

## 6. Naming

- **6.1** Models and classes: `PascalCase`; methods: `camelCase`; DB tables:
  `snake_case` plural; pivot tables name both models alphabetically.

## 7. Static analysis

- **7.1** For framework overrides whose parameter is unused — `toArray(Request
  $request)`, `withResponse(...)` — suppress with
  `@phpcsSuppress SlevomatCodingStandard.Functions.UnusedParameter`.
- **7.2** Suppress `SlevomatCodingStandard.TypeHints.PropertyTypeHint` for
  inherited untyped properties such as `$collects`.
- **7.3** Type read models with generics, for example
  `LengthAwarePaginator<int, array<string, mixed>>`.
- **7.4** A port and its implementation must not disagree between `list<T>`
  and `T[]`.

## 8. Environment

- **8.1** In a containerised project make agent-written files readable by the
  runtime user: `chmod -R go+rX <code paths>`.

## 9. Tests

- **9.1** If tests are requested, follow existing `tests/` patterns
  (`*Test.php`, PHPUnit, Feature/Unit) — introduce no new framework.
