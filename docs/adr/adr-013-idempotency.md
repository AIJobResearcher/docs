# ADR-013: Idempotency Strategy for Event and Request Processing

## Context

In a distributed system, messages can be delivered more than once (network
failures, restarts, retries). This can lead to duplication of applications,
meetings, indexing.

## Decision

We use a combination of three mechanisms:

1. **Idempotency‑Key** (synchronous APIs) – the client generates a unique key,
   the service stores it and returns a cached response on repeat (TTL 7 days).
2. **Deduplication by `event_id`** (asynchronous consumers) – each event has a
   unique `event_id`, the consumer checks whether it has already been processed.
3. **`processed_events` table** (primary key `event_id`) – before processing an
   event, we insert; if duplicate, ignore. The table is cleaned daily (TTL 7 days).

Business invariants (e.g., "one application per vacancy") serve as a second line
of defence.

## Why this decision

- Covers both synchronous and asynchronous scenarios.
- `Idempotency-Key` is standard for REST APIs.
- The `processed_events` table is simple and efficient.

## Alternatives

- Use only business invariants – not enough (does not prevent duplication of
  events with identical data).
- Use transactional deduplication at the database level (same table).

## Consequences

- All event consumers must implement `processed_events` check.
- API clients must generate `Idempotency-Key`.
- Slight increase in latency (one insertion into the DB).

## Related artifacts

- Section "Idempotency Strategy" in `architecture-overview.md`.
- ADR-011 (Outbox Pattern).
