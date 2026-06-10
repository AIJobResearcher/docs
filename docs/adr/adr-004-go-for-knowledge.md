# ADR-004: Using Go for the KnowledgeCenter Service

## Context

The KnowledgeCenter service manages long-term learning plans, tracks, and
progress. Main requirements: high performance for background recommendation
calculations, low memory consumption, and easy horizontal scaling.

## Decision

We chose **Go 1.22** with the Gin framework (REST API) and a RabbitMQ client.
Data is stored in PostgreSQL.

## Why this decision

- High performance (especially for parallel progress calculations).
- Low memory consumption (goroutines are lighter than threads).
- Easy horizontal scaling (compiles to a static binary).
- Good support for working with queues (RabbitMQ).

## Alternatives

- PHP (Symfony) – higher memory consumption, more complex for long-running
  background processes.
- Python – heavy for background calculations, consumes more memory.
- Java (Spring) – heavy, requires more resources.

## Consequences

- The team needs Go knowledge (or training).
- Fewer ready‑made libraries for AI, but KnowledgeCenter does not need them.
- Very lightweight deployment (single binary in Docker).

## Related artifacts

- ADR-009 (Capacity Planning) – minimal resources (1 vCPU / 1 GB).
- Section "Platform architecture" in `architecture-overview.md`.
