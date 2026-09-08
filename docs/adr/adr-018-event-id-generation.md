# ADR-018: Domain Event ID (`event_id`) Auto-Generation

## Context

Domain events were emitted with `event_id == aggregate_id`: the event reused the
identifier of the aggregate that produced it. When a single aggregate emits more
than one event (or an Imported event is generated independently), those events
carried the same `event_id`, which breaks the guarantees the infrastructure
relies on:

- the `processed_events` table uses `event_id` as its primary key for
  idempotency (ADR-013);
- the `outbox_messages` table relies on a UNIQUE `event_id` for the idempotent
  releaser (ADR-011).

With a shared `event_id`, several events of one aggregate could not be
distinguished and deduplication collapsed them into one.

## Decision

`event_id` is **auto-generated** (UUIDv4) in the base class `DomainEvent` for
every event instance. `aggregate_id` is supplied separately and identifies the
source aggregate; the two are independent and never equal. The rule is uniform
for all events, including the Imported events.

`event_id` therefore means: unique identifier of the concrete event instance.
`aggregate_id` means: identifier of the source aggregate, shared by all events
of the same aggregate.

Idempotency of aggregate creation is handled at the command-receipt level (an
existence check and/or `expected_version` validation), **not** through
`event_id == aggregate_id`.

## Why this decision

- Several events of one aggregate remain distinct, so `processed_events` (PK
  `event_id`) and the outbox UNIQUE index stay correct.
- Idempotent consumers deduplicate by the event instance identity, which is
  stable and meaningful regardless of the aggregate's own id.
- No caller-supplied or aggregate-derived id can accidentally collide across
  events of the same aggregate.

## Alternatives

- **`event_id == aggregate_id`** — rejected: makes events of one aggregate
  indistinguishable and breaks `processed_events`/outbox UNIQUE.
- **Caller/command supplies `event_id`** — rejected: leaks envelope concerns to
  callers and risks collisions and spoofing.
- **Deterministic id derived from aggregate + sequence** — rejected as
  over-engineered; auto UUIDv4 in the base class is simplest and uniform.

## Consequences

- `event_id` and `aggregate_id` are independent fields; they must not be
  compared or assumed equal.
- Outbox `UNIQUE(event_id)` and the `processed_events` PK remain correct for
  multiple events per aggregate.
- Idempotent consumers deduplicate by `event_id`; aggregate-creation idempotency
  relies on command receipt (`expected_version` / existence check).
- Documentation and AsyncAPI schemas state this invariant on the `event_id` /
  `aggregate_id` envelope fields.

## Related artifacts

- `app/Domain/Events/DomainEvent.php` (auto-generation of `event_id`).
- `docs/adr/adr-011-outbox-pattern.md`, `docs/adr/adr-013-idempotency.md`.
- `docs/asyncapi/events.yaml`, `docs/architecture-overview.md`,
  `docs/glossary.md`, `docs/domain/bounded-contexts/vacancies-market.md`.
