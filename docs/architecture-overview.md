# Architecture Overview for AIJobResearcher

**Status:** accepted
**Date:** 2026-09-28
**Version:** 1.12

> **Related documentation:** [Glossary](glossary.md) |
> [Context Map](context-map.md) | [Domain Vision](domain/domain-vision.md) |
> [Technical Requirements](technical-requirements.md) |
> [Domain Model](domain/domain-model.md) |
> [AI & RAG](domain/ai-rag-pipeline.md) | [README](./README.md)

This document covers the service landscape, the cross‑functional architectural
principles and the delivery pipeline of the platform. Requirements and capacity:
[Technical Requirements](technical-requirements.md).

## 1. Platform architecture (services, stacks, implementation order)

| # | Service             | Stack                                                    |
|---|---------------------|----------------------------------------------------------|
| 1 | Deploy & Docs       | Docker Compose, Kubernetes, GitHub Actions               |
| 2 | Vacancies Market    | PHP 8.5, Laravel 13, PostgreSQL 18, Redis                |
| 3 | ResearcherCrm       | PHP 8.5, Symfony 8.1, Doctrine ORM, PostgreSQL 18, Redis |
| 4 | Parsing&AIConnector | Python 3.14, FastAPI, Celery, RabbitMQ                   |
| 5 | Frontend            | React 19.3, Next.js 16.3 (App Router), TypeScript 7      |
| 6 | KnowledgeCenter     | Go 1.27, Gin, PostgreSQL 18, RabbitMQ                    |

**Runtime versions** are declared in this table only: C4 diagrams, ADRs and
other documents reference this section instead of repeating version numbers.
Only releases still supported upstream are listed — Symfony 8.1 (supported
until 2027-01-31) and Go 1.27 (the two newest Go majors are supported).

Service responsibilities – in the bounded context files; context ↔ service
mapping – [Context Map](context-map.md) §1.

## 2. Cross‑functional architectural principles

### 2.1 Clean Architecture

Layers: **Presentation → Application → Domain → Infrastructure**; the domain
layer is isolated from frameworks.

### 2.2 Event‑Driven Architecture

Services integrate asynchronously through events (RabbitMQ): scalability, loose
coupling, fault tolerance. Synchronous REST is used only where a caller needs an
immediate answer – relationships in [Context Map](context-map.md) §2; external
integrations and ACL – [ADR-015](./adr/adr-015-acl.md).

### 2.3 Event Versioning

Each event carries `event_version`; breaking changes increase the version and
the old version is published in parallel for at least 30 days. Compatibility and
deprecation rules – [ADR-012](./adr/adr-012-event-versioning.md); generation and
uniqueness of `event_id` – [ADR-018](./adr/adr-018-event-id-generation.md).

### 2.4 Idempotency

Synchronous APIs use `Idempotency-Key`; asynchronous consumers deduplicate by
`event_id` – [ADR-013](./adr/adr-013-idempotency.md).

### 2.5 Outbox

An event is written to the outbox table in the same transaction as the
aggregate, then published to RabbitMQ by a separate publisher –
[ADR-011](./adr/adr-011-outbox-pattern.md).

## 3. CI/CD and contract publication

- **Delivery:** every service is shipped as a container; Docker Compose locally,
  Kubernetes in production, Blue‑Green for stateless services, Canary planned.
  Database migrations follow the Expand‑Contract principle –
  [ADR-008](./adr/adr-008-deployment-migrations.md).
- **Contracts:** OpenAPI/AsyncAPI specifications are published from the service
  repositories into `docs/api/`; CI validates Markdown, YAML, OpenAPI and links
  (`.github/workflows/ci.yml`).
