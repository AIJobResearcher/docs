# AIJobResearcher – Documentation Home

**Status:** accepted
**Date:** 2026-09-27

[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

**Target load:** 50,000 concurrent active users
**Version:** 1.16

## What is this?

Welcome to the documentation of the AIJobResearcher platform. Here you will find
a complete description of the architecture, requirements, domain model,
processes, and infrastructure.

## Key success metrics

Product goals and business metrics: [Domain Vision](./domain/domain-vision.md)
§5. Service level objectives (availability, latency, capacity):
[Technical Requirements](./technical-requirements.md).

## Architecture in a nutshell

Microservices (PHP, Python, Go), event bus RabbitMQ, PostgreSQL with synchronous
replication, Redis, OpenSearch for search, Kubernetes with HPA,
OpenTelemetry + Jaeger + Prometheus + Loki.

## Documentation

| File / Folder | Content |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Technical Requirements](./technical-requirements.md) | NFR, SLO, capacity, security, API, observability, load testing, risks |
| [Architecture Overview](./architecture-overview.md) | Services, stacks and implementation order, Clean Architecture, EDA, versioning, idempotency, outbox, CI |
| [Domain Model](./domain/domain-model.md) | Map of aggregates and entities per bounded context (data ownership), links to the detailed files |
| [Domain Vision](./domain/domain-vision.md) | Strategic goals, core and supporting domains, competitive advantages, success metrics, scope and non-goals |
| [Roadmap](./roadmap.md) | Capability stages of the platform, from automatic vacancy updates to the learning centre |
| [Glossary](./glossary.md) | Glossary of terms (Ubiquitous Language) |
| [Context Map](./context-map.md) | Interaction map of bounded contexts (upstream/downstream), published language |
| [Bounded Contexts](./domain/bounded-contexts/) | Detailed descriptions of each bounded context: - [Vacancies Market](./domain/bounded-contexts/vacancies-market.md) - [ResearcherCrm](./domain/bounded-contexts/researcher-crm.md) - [Parsing&AIConnector](./domain/bounded-contexts/parsing-ai-connector.md) - [KnowledgeCenter](./domain/bounded-contexts/knowledge-center.md) |
| [AI & RAG Pipeline](domain/ai-rag-pipeline.md) | RAG pipeline flow: document processing, chunking, vector search, context assembly, prompts (decisions — ADR-006/007/010) |
| [AsyncAPI Events](./asyncapi/events.yaml) | Event catalogue in AsyncAPI 3.0 format (event design pending) |
| **API specifications (OpenAPI)** | Automatically generated specifications for each service: - [api/vacancies/](api/vacancies-market/) - [api/researcher-crm/](./api/researcher-crm/) - [api/parsing-ai-connector/](./api/parsing-ai-connector/) - [api/knowledge-center/](./api/knowledge-center/) |
| [C4 diagrams](./c4/) | System context, containers and per-service components ([index](./c4/README.md)) |
| [ADR](./adr/) | Architectural decisions (microservices, RabbitMQ, RAG, outbox, capacity planning, etc.) |
| [Event Storming](./event-storming/) | Event-flow placeholders per context; aggregates and rules live in the bounded context files |
| [UI Page Specs](./ui/) | Frontend page specifications and user flows |
| **Deploy & Infrastructure** | Deployment files (located in the repository root and in the `deploy/` folder): - [Local docs Docker Compose](../deploy/docs/local/compose.yml) - [GitHub Actions workflows](../.github/workflows/) |

All artifacts are maintained as **Documentation as Code** – CI checks for
up‑to‑dateness.
