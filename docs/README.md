# AIJobResearcher – Documentation Home

[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

**Target load:** 50,000 concurrent active users
**Version:** 1.0

## What is this?

Welcome to the documentation of the AIJobResearcher platform. Here you will find
a complete description of the architecture, requirements, domain model,
processes, and infrastructure.

## Key success metrics

- Reduce time from start of job search to first interview invitation by 30%
- Double the conversion rate from applications to invitations
- Share of job seekers who use AI recommendations > 60%
- Critical service availability 99.9%
- Vacancy search latency p95 ≤ 300 ms

## Architecture in a nutshell

Microservices (PHP, Python, Go), event bus RabbitMQ, PostgreSQL with synchronous
replication, Redis, OpenSearch for search, Kubernetes with HPA,
OpenTelemetry + Jaeger + Prometheus + Loki.

## Documentation

| File / Folder | Content |
| --- | --- |
| [Technical Requirements](./technical-requirements.md) | NFR, SLO, capacity, security, API, observability, load testing, risks |
| [Architecture Overview](./architecture-overview.md) | Services, communication, bounded contexts, Clean Architecture, EDA, ACL, search, versioning, idempotency, outbox |
| [Domain Model](./domain/domain-model.md) | Quick overview of domains, cross-domain processes, data ownership, aggregates summary (links to detailed files) |
| [Domain Vision](./domain/domain-vision.md) | Strategic goals, actors, competitive advantages |
| [Glossary](./glossary.md) | Glossary of terms (Ubiquitous Language) |
| [Context Map](./context-map.md) | Interaction map of bounded contexts (upstream/downstream) |
| [Bounded Contexts](./domain/bounded-contexts/) | Detailed descriptions of each bounded context: - [Vacancies Service](./domain/bounded-contexts/vacancies.md) - [Researcher CRM](./domain/bounded-contexts/researcher-crm.md) - [Parsing&AIConnector](./domain/bounded-contexts/parsing-ai-connector.md) - [KnowledgeCenter](./domain/bounded-contexts/knowledge-center.md) |
| [AI & RAG Pipeline](domain/ai-rag-pipeline.md) | RAG pipeline, AI providers, embeddings, vector DB, parsing, caching, prompts |
| [AsyncAPI Events](./asyncapi/events.yaml) | Specification of all domain events in AsyncAPI 2.6.0 format |
| **API specifications (OpenAPI)** | Automatically generated specifications for each service: - [api/vacancies/](./api/vacancies/) - [api/researcher-crm/](./api/researcher-crm/) - [api/parsing-ai-connector/](./api/parsing-ai-connector/) - [api/knowledge-center/](./api/knowledge-center/) |
| **BDD scenarios (Gherkin)** | Executable scenarios for each service: - [Vacancies: manage vacancies](./features/vacancies/managing_vacancies.feature) - [Researcher CRM: schedule interviews](./features/researcher-crm/interview-scheduling.feature) - [Parsing&AIConnector: parse vacancies](./features/parsing-ai-connector/parsing-vacancies.feature) - [KnowledgeCenter: learning plan](./features/knowledge-center/learning-plan.feature) |
| [C4 diagrams](./c4/) | Context, containers, components |
| [ADR](./adr/) | Architectural decisions (microservices, RabbitMQ, RAG, outbox, capacity planning, etc.) |
| [Event Storming](./event-storming/) | Event modeling for each domain |
| **Deploy & Infrastructure** | Deployment files (located in the repository root and in the `deploy/` folder): - [Local docs Docker Compose](../deploy/docs/local/compose.yml) - [GitHub Actions workflows](../.github/workflows/) |

All artifacts are maintained as **Documentation as Code** – CI checks for
up‑to‑dateness.
