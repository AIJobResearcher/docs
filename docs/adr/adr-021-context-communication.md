# ADR-021: Communication between Contexts: Queries, Commands and Events

**Status:** accepted
**Date:** 2026-09-30

## Context

Four services communicate over RabbitMQ events and REST: Vacancy Management
(Vacancies Market), Job Search & CRM (ResearcherCrm), AI & Parsing
(Parsing&AIConnector) and Learning Management (KnowledgeCenter). The platform is
event-driven ([ADR-005](./adr-005-rabbitmq-broker.md)), and the
[Context Map](../context-map.md) §2 fixes each interaction, but the rule
"asynchronous events by default, synchronous REST only where a caller needs an
immediate answer" ([Architecture Overview](../architecture-overview.md) §2.2)
does not say which kind of interaction uses which transport, and left two cases
open:

- May a context read another context's reference data over the API? The parser
  owns the `Portal` registry (AI & Parsing §5.1), while Vacancy Management
  stores sources that reference a `Portal` by id.
- How does a context ask another to change an external system? Vacancy
  Management requests portal updates from the parser (AI & Parsing §3.8), and
  the portal is slow and failure-prone.

## Decision

Classify every cross-context interaction by its nature, then use the matching
transport:

- **Query** – a read of data owned by another context. Use the owner's
  synchronous read API, with a time-boxed cache on the caller side; the caller
  degrades to the cache when the owner is unavailable.
- **Command** – an intent to change state the caller does not own. Use an
  asynchronous RabbitMQ command; the receiver answers with a result event. Use
  synchronous REST only when the caller cannot complete its own request without
  the result.
- **Event** – a fact that already happened. Use asynchronous RabbitMQ events,
  published through the outbox ([ADR-011](./adr-011-outbox-pattern.md)),
  versioned ([ADR-012](./adr-012-event-versioning.md)) and deduplicated by
  `event_id` ([ADR-013](./adr-013-idempotency.md)).

Settled cases:

- `Portal` registry (AI & Parsing) read for `Source` labels (Vacancy
  Management): query — synchronous REST read plus a TTL cache; the registry
  stays with its owner and no portal data is replicated into the catalogue.
- Portal update request (AI & Parsing §3.8): command — asynchronous, with a
  result event.
- Parsed portal records (AI & Parsing §2.9): event — the parser publishes, and
  Vacancy Management owns normalization, matching and the catalogue decision.
- AI recommendation and summary requests: synchronous REST, because the caller
  needs the answer inside its own request; generated recommendations are pushed
  as events.

Additional rules:

- A context never writes another context's aggregates synchronously and never
  shares its database or tables.
- Events state facts, not requests; a request/response over events with
  correlation ids is not used where a query or a command fits.
- Every synchronous cross-context call carries a timeout and a circuit breaker,
  and every query of a foreign reference keeps a cache to avoid temporal
  coupling.
- Command and result-event pairs are idempotent: the command carries a key
  (`Idempotency-Key`) and the result an `event_id`.

## Why this decision

- The nature of the interaction, not convention, decides the transport: reads
  that block a request stay synchronous, everything that can be retried or
  buffered is asynchronous.
- Reference data stays in its owning context, so no context ends up with a
  partial copy of a catalogue it does not own.
- Long-running, external-facing work (portal writes) never holds a caller's
  request open, which keeps the synchronous surface small and its latency
  predictable.
- The three-way classification is testable in review: every interaction in the
  Context Map names its kind, so a new integration is checked against the rule
  instead of being decided ad hoc.

## Alternatives

- **All interactions as events** – reference reads would need request/response
  over events or a full replica of foreign catalogues; rejected: extra state,
  staleness and correlation bookkeeping with no benefit for a low-volume,
  near-static list.
- **All interactions as synchronous REST** – rejected: temporal coupling,
  cascading failures and distributed-monolith behaviour; a portal write would
  block a catalogue request.
- **Shared database or distributed transactions** – rejected: it breaks data
  ownership (Domain Model §1) and the microservice boundary
  ([ADR-001](./adr-001-microservices.md)).
- **Enterprise service bus** – rejected: overkill for four services, and it
  moves the contract into infrastructure ([ADR-015](./adr-015-acl.md)).

## Consequences

- The Context Map §2 must state the kind (query, command or event) for every
  interaction, and be updated when an interaction is added.
- Callers of queries own a cache and its invalidation; owners own the read API
  contract in OpenAPI.
- Commands need a result event, an idempotency key and a timeout on the
  requestor side; the receiving side needs a retry policy and a dead-letter
  path.
- Some flows become eventually consistent by design; they are bound by the
  consistency targets of the Glossary (`Eventual Consistency`).

## Related artifacts

- [Context Map](../context-map.md) §2 – the interaction matrix.
- [Architecture Overview](../architecture-overview.md) §2.2 – event-driven
  architecture.
- [ADR-005](./adr-005-rabbitmq-broker.md),
  [ADR-011](./adr-011-outbox-pattern.md),
  [ADR-012](./adr-012-event-versioning.md),
  [ADR-013](./adr-013-idempotency.md) – broker, outbox, versioning, idempotency.
- [ADR-015](./adr-015-acl.md) – anti-corruption layer for external systems.
