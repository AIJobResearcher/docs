# ADR Index

Architecture Decision Records capture the platform's architectural choices
and their rationale — one file per decision. The required ADR structure is
defined in `../.ai-agent/standards/docs-files-standards.md` (ADR). Status and
date fields are not used yet; they can be introduced when lifecycle tracking
(proposed/accepted/superseded) starts.

| ADR | Decision | File |
| --- | --- | --- |
| 001 | Choosing Microservices Architecture | [adr-001-microservices.md](./adr-001-microservices.md) |
| 002 | Placing the Job Seeker (Researcher) in the ResearcherCrm Service | [adr-002-researcher-owner.md](./adr-002-researcher-owner.md) |
| 003 | Using Python for the Parsing & AI Service | [adr-003-python-for-ai-parsing.md](./adr-003-python-for-ai-parsing.md) |
| 004 | Using Go for the KnowledgeCenter Service | [adr-004-go-for-knowledge.md](./adr-004-go-for-knowledge.md) |
| 005 | Choosing RabbitMQ as the Message Broker | [adr-005-rabbitmq-broker.md](./adr-005-rabbitmq-broker.md) |
| 006 | AI Model Integration Strategy | [adr-006-ai-integration.md](./adr-006-ai-integration.md) |
| 007 | External Portal Parsing Strategy | [adr-007-parsing-strategy.md](./adr-007-parsing-strategy.md) |
| 008 | Deployment and Migrations Strategy | [adr-008-deployment-migrations.md](./adr-008-deployment-migrations.md) |
| 009 | Capacity Planning | [adr-009-capacity-planning.md](./adr-009-capacity-planning.md) |
| 010 | Choosing Qdrant and the RAG Strategy for AI Recommendations | [adr-010-qdrant-rag.md](./adr-010-qdrant-rag.md) |
| 011 | Outbox Pattern for Reliable Event Publication | [adr-011-outbox-pattern.md](./adr-011-outbox-pattern.md) |
| 012 | Event Versioning Policy | [adr-012-event-versioning.md](./adr-012-event-versioning.md) |
| 013 | Idempotency Strategy for Event and Request Processing | [adr-013-idempotency.md](./adr-013-idempotency.md) |
| 014 | Choosing OpenSearch / Elasticsearch for Full-Text Search | [adr-014-opensearch.md](./adr-014-opensearch.md) |
| 015 | Using an Anti-Corruption Layer (ACL) for External Systems | [adr-015-acl.md](./adr-015-acl.md) |
| 016 | Logical Data Isolation for Job Seekers (Multi-Tenancy for B2C) | [adr-016-multitenancy.md](./adr-016-multitenancy.md) |
| 017 | Aggregate Creation and Hydration (Domain ↔ Eloquent Bridge) | [adr-017-aggregate-creation-and-hydration.md](./adr-017-aggregate-creation-and-hydration.md) |

## 1. How to add an ADR

1. Take the next free number (currently `018`).
2. Create `adr-018-<short-slug>.md` with sections in the fixed order from
   the standards file: Context, Decision, Why this decision, Alternatives,
   Consequences, Related artifacts.
3. Add a row to the table above.
