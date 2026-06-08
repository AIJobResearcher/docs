# ADR-009: Capacity Planning

## Context

The system is designed for 50,000 concurrent active users and a peak RPS of up to
20,000. Without pre‑calculating resources (CPU, RAM, disk, network), we cannot
guarantee meeting SLOs for latency and availability.

## Decision

Capacity planning for the production environment is done (table in the "Capacity
Planning" section of `technical-requirements.md`). Main parameters:

- Minimum number of replicas for each service with a 30% buffer above the
  calculated average load.
- Resources per replica (CPU / RAM) based on prototype testing and expert
  assessment.
- Storage capacity (PostgreSQL, RabbitMQ, OpenSearch, Redis) for 1 year of growth.
- Network requirements (throughput, latency ≤ 1 ms inside the data centre).

## Why this decision

- Balance between cost and performance: PHP services use 2 vCPU / 2 GB RAM (typical
  for Laravel/Symfony with opcache).
- Go service KnowledgeCenter is lightweight (1 vCPU / 1 GB) due to efficient memory
  usage.
- Python service is given more resources (4 vCPU / 8 GB) because of heavy AI tasks
  and parsing.
- Databases get dedicated instances with SSDs and replicas for fault tolerance.
- 30% buffer allows handling sudden spikes without immediate scaling.

## Alternatives

- Use fewer replicas and rely on HPA – risk of not reacting fast enough to a
  sudden increase.
- Place all services on a single node – not suitable for high load.

## Consequences

- Infrastructure costs are fixed and predictable.
- Horizontal scaling via HPA (CPU 70% / RabbitMQ queue depth) complements the base
  planning.
- If functionality changes (e.g., a new feature that increases data volume),
  capacity must be recalculated.
- Regular review (e.g., quarterly) based on real‑world metrics.

## Related artifacts

- Section "Capacity Planning" in `technical-requirements.md`.
- ADR-005 (scaling via HPA).
- Load testing results (section "Performance Testing Plan").
