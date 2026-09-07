# ADR-017: Aggregate Creation and Hydration (Domain ↔ Eloquent Bridge)

## Context

The domain layer is isolated from the framework (Clean Architecture):
aggregates (`Vacancy`, `Employer`, `Job`, `Requirement`) are `final` classes
with private constructors and must not depend on Laravel/Eloquent. Eloquent
models live only in `Infrastructure` as an access mechanism; the domain entities
are NOT Eloquent models and know nothing about the DB, Active Record, or
serialization.

Each aggregate exposes a single named factory `create(...)` that performs
business validation, applies creation defaults (e.g. `status = OPEN`,
`version = 1`, timestamps = now), and **records a domain event**
(e.g. `VacancyImportedEvent`).

`create()` cannot be used for reads from the DB: it forces `OPEN`, resets
`version` to 1, overwrites timestamps, and would emit a domain event on every
load. A separate "restoration" entry point is therefore required that does NOT
go through `create()`, does NOT apply business validation, and does NOT emit
events.

PHP constraint: a private constructor is only visible inside its own class;
there is no package/`friend`/`internal` visibility. To let an Infrastructure
mapper assemble an aggregate, one of these must be relaxed: constructor
visibility, reflection, or a static entry point on the aggregate.

The decision is verified against two independent canonical sources:
`.dsh/docs/answer-aggregate-hydration.md` and
`.dsh/docs/answer-domain-eloquent-architecture.md`, which both converge on the
same design (SSW Clean Architecture ADR "Use the Factory Pattern to Create
Aggregates"; Kamil Grzybek, modular-monolith-with-ddd #214; Udi Dahan, "Don't
create aggregate roots").

## Decision

We use a **private full-state constructor + two static entry points on the
aggregate**:

1. **Private constructor** of the full state (including `version`, timestamps,
   status, child collections). Assigns state only; validates nothing beyond
   invariants that hold for any state; emits no events.
2. **`create(...)`** — the single creation point: business validation, creation
   defaults, records the domain event (`VacancyImportedEvent`). Unchanged in
   essence.
3. **`reconstitute(...)`** — the single hydration point: takes persisted state
   "as is", with no business validation and no events, and calls the same
   private constructor. Intended callers are only Infrastructure mappers;
   Application-layer calls are prohibited by an architectural test.

Why this over the alternatives:

- **GoF Factory Method / DDD Factory** — knowledge of "how to build a valid
  aggregate" belongs to the domain; the private constructor guarantees there is
  no way past the factory (SSW ADR).
- **Restoration ≠ creation** (Grzybek #214) — business validation must not be
  re-run on read, so historical rows remain readable after rules are
  tightened. Structural validity (UUID, URL format, salary range) stays in the
  VO constructors and fires always — an accepted minimal contract.
- **PHP has no package-private** — the private constructor is unreachable by the
  mapper, so the restoration entry is a public static method with PHP 8 named
  arguments: type-safe, visible to static analysis and the IDE, and refactorable.
  Reflection was rejected: it cannot initialize promoted `readonly` properties
  from outside and is invisible to static analysis.

Persistence follows from this:

- **Create vs update** — the repository decides by the actual existence of a row
  (`whereKey($id)->exists()`), NOT by an `isNew` flag in the domain (domain must
  not know about persistence).
- **Optimistic locking** — update guarded by
  `WHERE id = ? AND version = <expected>`, where `<expected>` is the version
  before the domain mutation (aggregate methods already increment `version`).
  Zero affected rows → retryable `OptimisticLockException`.
- **Child collections & hidden state** — aggregates expose snapshot getters for
  child collections; children expose full state getters including behavioral
  fields (e.g. `unassignedAt`), which are introduced into child constructors as
  optional trailing parameters.
- **Outbox** — domain events (`releaseEvents()`) are written to
  `outbox_messages` in the same `DB::transaction` as the aggregate change
  (ADR-011); `releaseEvents()` is called first inside the transaction so the
  payload is serialized once. A dedicated Unit of Work is NOT introduced yet
  (YAGNI) — the repository is the persistence boundary of a single aggregate.

## Why this decision

- Keeps the dependency direction strict: `Domain ← Infrastructure`, no framework
  leaks into the domain; Eloquent stays an Infrastructure-only table gateway.
- Events are emitted on creation/behaviour, never on hydration.
- Historical persisted data stays readable after business rules change.
- A single, uniform pattern applies to every aggregate (see Consistency below),
  enforced by architectural tests rather than a "magic" base class.
- Type-safe, IDE/static-analysis friendly hydration without reflection.

## Alternatives

- **Public (loose) constructor** — invites a bare `new` from Application and
  weakens exactly what the private constructor protects.
- **`protected` constructor + subclass in Infrastructure** — incompatible with
  `final class`; still invisible to an unrelated mapper; one fragile subclass per
  aggregate.
- **Reflection (`newInstanceWithoutConstructor` / `setValue`)** — cannot
  initialize promoted `readonly` properties from outside; magic, invisible to
  static analysis and IDE, breaks on refactoring.
- **Separate domain factory class (`VacancyFactory`)** — over-engineering for a
  single creation scenario (YAGNI); revisit when a second/third scenario or
  external-dependency assembly appears.
- **Thick Eloquent models as domain objects (Active Record as domain model)** —
  the main source of technical debt in Laravel: domain fuses with the DB,
  Eloquent events substitute for domain events, tests require a DB. Rejected:
  loses the isolation the design exists to preserve.

## Consistency (uniform pattern for all aggregates)

Convention + ADR + architectural tests, per aggregate `Xxx`:

1. private full-state constructor (no validation, no events);
2. `create()` — single creation point (validation, defaults, events);
3. `reconstitute()` — single restoration point (no events, no business
   validation), callable only by Infrastructure mappers;
4. snapshot getters for child collections; full getters on children (incl.
   behavioral fields);
5. quartet `Model + Entity + Mapper + Repository`; the repository implements the
   domain interface;
6. events only via outbox in the same transaction as the aggregate write.

Architectural tests (pest + deptrac + PHPStan):

- no public constructor on aggregates (reflection check);
- Application never calls `::reconstitute(` or `new <Aggregate>(`;
- `::reconstitute(` is allowed only in `app/Infrastructure/**/Mappers/*`.

## Consequences

- Two entry points per aggregate (`create()` / `reconstitute()`); the private
  constructor stays private.
- Structural invariants live in VO constructors and also fire on hydration — an
  accepted compromise; business rules are intentionally not re-run on read.
- Child "hidden" state (`unassignedAt`, version, children) is serialized via
  snapshot getters; `reconstitute()` restores it as-is.
- Repository owns the transaction, optimistic locking, child reconciliation and
  outbox writes for a single aggregate.
- When to revisit: a command mutating several aggregates in one transaction →
  Application-level Unit of Work; a second/third creation scenario or assembly
  with external dependencies → a separate domain factory; mechanical mapper
  routine → a mapper/serializer such as Valinor; event sourcing → the
  `reconstitute()` form is already compatible with `fromHistory()`.

## Related artifacts

- SSW Clean Architecture — ADR "Use the Factory Pattern to Create Aggregates".
- Kamil Grzybek, modular-monolith-with-ddd — discussion #214.
- Udi Dahan, "Don't create aggregate roots".
- `docs/adr/adr-011-outbox-pattern.md`, `docs/adr/adr-013-idempotency.md`.
