# ADR-001: Choosing Microservices Architecture

## Context

The system must scale to 50,000 concurrent users, support independent
development of functionality (search, AI, learning), and demonstrate modern
approaches for an enterprise demo.

## Decision

We chose a microservices architecture with six services: Deploy & Docs,
Vacancies, ResearcherCrm, Parsing&AIConnector, Frontend, KnowledgeCenter. Each
service has its own database, codebase, CI/CD pipeline, and lifecycle.

## Why this decision

- Independent scaling (heavy services can be replicated separately).
- Independent releases (updating one service does not require restarting all).
- Clear separation by bounded contexts (DDD).
- Technological independence: PHP for CRM, Python for AI, Go for learning.

## Alternatives

- Modular monolith – simpler to develop, but does not demonstrate microservices
  patterns and is harder to scale parts separately.
- Serverless (FaaS) – not suitable for long-running processes (parsing, AI) and
  complex transactions.

## Consequences

- Complexity of distributed transactions (solved by event-driven approach and
  eventual consistency).
- Need for a message broker (RabbitMQ).
- DevOps overhead (Kubernetes, CI/CD).
- Inter-service calls require APIs and events.

## Related artifacts

- ADR-005 (RabbitMQ).
- ADR-008 (deployment and migrations).
- Section "Platform architecture" in `architecture-overview.md`.
