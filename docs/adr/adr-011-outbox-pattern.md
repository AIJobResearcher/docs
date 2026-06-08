# ADR-011: Outbox Pattern for Reliable Event Publication

## Context

When saving an aggregate (e.g., an application) and then publishing the
`ReplyCreated` event to RabbitMQ, a failure can occur: the event is not sent, but
the aggregate is saved. Direct publication inside a database transaction is
impossible because RabbitMQ does not support two‑phase commit (XA).

## Decision

We use the **Transactional Outbox** pattern:

- Each service’s database contains an `outbox_messages` table with fields `id`,
  `event_id`, `event_type`, `payload`, `published_at`, `retry_count`,
  `last_error`.
- In the same transaction that saves the aggregate, the service writes the event
  to the outbox.
- A separate asynchronous process (publisher) periodically (every 100 ms) reads
  the outbox, sends events to RabbitMQ, and marks them `published_at`. On error,
  it increments `retry_count` and retries with exponential backoff.
- After 10 failed attempts, the record is marked as failed and an alert is sent.

## Why this decision

- Guarantees atomicity between state persistence and event publication.
- Does not require XA transactions or two‑phase commit.
- Allows recovery after failures (outbox records are not lost).
- Works with all used databases (PostgreSQL).
- Simpler to implement than CDC solutions (Debezium) and adds no extra components.

## Alternatives

- **Direct publication inside a transaction** – does not guarantee delivery on
  failure.
- **CDC with Debezium** – requires additional infrastructure (Kafka Connect),
  harder to operate.
- **Two‑phase commit (XA)** – not supported by RabbitMQ, reduces performance.

## Consequences

- Must create an outbox table in each publisher service’s database.
- The publisher runs in the background (a separate worker).
- Consumers must be idempotent (see ADR-013) because outbox gives at‑least‑once
  delivery.
- Delay between aggregate save and event delivery increases by the publisher’s
  polling interval (on average up to 100 ms).
- Monitor outbox size and number of failed attempts via Prometheus.

## Related artifacts

- ADR-013 (Idempotency Strategy).
- ADR-005 (RabbitMQ choice).
- Section "Outbox Pattern" in `architecture-overview.md`.
