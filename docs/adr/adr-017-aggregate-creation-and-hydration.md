# ADR-017: Aggregate Creation and Hydration (Domain ↔ Eloquent Bridge)

**Status:** accepted
**Date:** 2026-09-27

## Context

The domain layer is isolated from the framework (Clean Architecture):
aggregates (`Vacancy`, `Employer`, `Job`, `Requirement`) are `final` classes
with private constructors and must not depend on Laravel/Eloquent. Eloquent
models live only in `Infrastructure` as an access mechanism; domain entities are
NOT Eloquent models and know nothing about the DB, Active Record or
serialization.

`create()` cannot be used for reads from the DB: it forces `OPEN`, resets
`version` to 1, overwrites timestamps and would emit a domain event on every
load. A separate "restoration" entry point is therefore required that does NOT
go through `create()`, does NOT apply business validation and does NOT emit
events.

PHP constraint: a private constructor is visible only inside its own class;
there is no package/`friend`/`internal` visibility. To let an Infrastructure
mapper assemble an aggregate, either constructor visibility, reflection or a
static entry point on the aggregate has to be relaxed.

The decision was verified against two independent canonical sources
(`.dsh/docs/answer-aggregate-hydration.md`,
`.dsh/docs/answer-domain-eloquent-architecture.md`), which converge on the same
design (SSW Clean Architecture ADR "Use the Factory Pattern to Create
Aggregates"; Kamil Grzybek, modular-monolith-with-ddd #214; Udi Dahan, "Don't
create aggregate roots").

## Decision

We use a **private full-state constructor + two static entry points on the
aggregate**:

1. **Private constructor** of the full state (including `version`, timestamps,
   status, child collections). Assigns state only; validates nothing beyond
   invariants that hold for any state; emits no events.
2. **`create(...)`** — the single creation point: business validation, creation
   defaults, records the domain event.
3. **`reconstitute(...)`** — the single hydration point: takes persisted state
   "as is", with no business validation and no events, and calls the same
   private constructor. Only Infrastructure mappers may call it; Application
   calls are prohibited by an architectural test.

Persistence follows from this:

- **Create vs update** — the repository decides by the actual existence of a row
  (`whereKey($id)->exists()`), NOT by an `isNew` flag in the domain.
- **Optimistic locking** — update guarded by
  `WHERE id = ? AND version = <expected>`, where `<expected>` is the version
  before the domain mutation (aggregate methods already increment `version`).
  Zero affected rows → retryable `OptimisticLockException`.
- **Child collections and hidden state** — aggregates expose snapshot getters
  for child collections; children expose full state getters including
  behavioural fields (e.g. `unassignedAt`), introduced as optional trailing
  constructor parameters.
- **Outbox** — `releaseEvents()` writes domain events to `outbox_messages` in
  the same `DB::transaction` as the aggregate change (ADR-011) and is called
  first inside the transaction, so the payload is serialized once. No dedicated
  Unit of Work yet (YAGNI): the repository is the persistence boundary of a
  single aggregate.

Convention per aggregate `Xxx`, enforced by architectural tests:

1. private full-state constructor (no validation, no events);
2. `create()` — single creation point (validation, defaults, events);
3. `reconstitute()` — single restoration point (no events, no business
   validation), callable only by Infrastructure mappers;
4. snapshot getters for child collections; full getters on children, including
   behavioural fields;
5. quartet `Model + Entity + Mapper + Repository`; the repository implements the
   domain interface;
6. events only through the outbox, in the transaction of the aggregate write.

Architectural tests (pest + deptrac + PHPStan) check that aggregates have no
public constructor, that Application never calls `::reconstitute(` or
`new <Aggregate>(`, and that `::reconstitute(` appears only in
`app/Infrastructure/**/Mappers/*`.

## Why this decision

- Knowledge of "how to build a valid aggregate" belongs to the domain, and the
  private constructor guarantees there is no way past the factory (SSW ADR).
- Restoration ≠ creation (Grzybek #214): business validation must not re-run on
  read, so historical rows stay readable after rules are tightened. Structural
  validity (UUID, URL format, salary range) stays in VO constructors and fires
  always — an accepted minimal contract.
- PHP has no package-private visibility: the private constructor is unreachable
  by the mapper, so restoration is a public static method with named
  arguments — type-safe, visible to static analysis and the IDE, and
  refactorable.
- Keeps the dependency direction strict (`Domain ← Infrastructure`); Eloquent
  stays an Infrastructure-only table gateway.
- Events are emitted on creation and behaviour, never on hydration.
- One uniform pattern applies to every aggregate, enforced by tests rather than
  a "magic" base class.

## Alternatives

- **Public (loose) constructor** — invites a bare `new` from Application and
  weakens exactly what the private constructor protects.
- **`protected` constructor + subclass in Infrastructure** — incompatible with
  `final class`; still invisible to an unrelated mapper; one fragile subclass
  per aggregate.
- **Reflection (`newInstanceWithoutConstructor` / `setValue`)** — cannot
  initialize promoted `readonly` properties from outside; magic, invisible to
  static analysis and IDE, breaks on refactoring.
- **Separate domain factory class (`VacancyFactory`)** — over-engineering for a
  single creation scenario (YAGNI); revisit when a second or third scenario or
  external-dependency assembly appears.
- **Thick Eloquent models as domain objects (Active Record as domain model)** —
  the main source of technical debt in Laravel: the domain fuses with the DB,
  Eloquent events substitute for domain events, tests require a DB. Rejected:
  loses the isolation this design exists to preserve.

## Consequences

- Two entry points per aggregate (`create()` / `reconstitute()`); the private
  constructor stays private.
- Structural invariants live in VO constructors and also fire on hydration — an
  accepted compromise; business rules are intentionally not re-run on read.
- Child hidden state (`unassignedAt`, version, children) is serialized through
  snapshot getters; `reconstitute()` restores it as-is.
- The repository owns the transaction, optimistic locking, child reconciliation
  and outbox writes for a single aggregate.
- Revisit when: a command mutates several aggregates in one transaction
  (Application-level Unit of Work); a second or third creation scenario appears
  or assembly needs external dependencies (separate domain factory); the mapper
  becomes mechanical (mapper/serializer such as Valinor); event sourcing is
  introduced (`reconstitute()` is already compatible with `fromHistory()`).

## Related artifacts

- SSW Clean Architecture — ADR "Use the Factory Pattern to Create Aggregates".
- Kamil Grzybek, modular-monolith-with-ddd — discussion #214.
- Udi Dahan, "Don't create aggregate roots".
- `docs/adr/adr-011-outbox-pattern.md`, `docs/adr/adr-013-idempotency.md`.
