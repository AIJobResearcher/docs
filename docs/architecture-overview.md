# Architecture Overview for AIJobResearcher

**Version:** 1.0
**Target load:** 50,000 concurrent users

> **Related documentation:** [Glossary](glossary.md) |
> [Technical Requirements](technical-requirements.md) |
> [Domain Model](domain/domain-model.md) |
> [AI & RAG](domain/ai-rag-pipeline.md) | [README](./README.md)

## 1. Brief description

AIJobResearcher is a platform for job seekers that combines job search from
multiple portals, managing replies and meetings, AI recommendations, and
long‑term learning. The system demonstrates DDD, Clean Architecture,
Event‑Driven Architecture, CQRS, High Load, TDD, Microservices, Eventual
Consistency, Observability.

## 2. Domain Vision (short)

Full description: `/docs/domain/domain-vision.md`

- **Core Domain:** Job Search & CRM
- **Supporting Domains:** Vacancy Market, AI & Parsing, Knowledge & Learning
- **Generic Domains:** authentication, audit, RabbitMQ, Redis, OpenSearch,
  Kubernetes

## 3. Platform architecture (services, stacks, implementation order)

| # | Service | Stack | Notes |
| --- | --- | --- | --- |
| 1 | Deploy & Docs | DevOps | Docker Compose, K8s, GitHub Actions, ADR |
| 2 | Vacancies | PHP 8.5, Laravel 13,<br>PostgreSQL 16, Redis | employers, vacancies,<br>interviewers, import |
| 3 | ResearcherCrm | PHP 8.5, Symfony 7.1,<br>Doctrine ORM, PostgreSQL 16,<br>Redis | job seekers, desired jobs,<br>replies, meetings, messages,<br>analytics |
| 4 | Parsing&AIConnector | Python 3.12, FastAPI,<br>Celery, RabbitMQ | portal parsing, AI models,<br>recommendations |
| 5 | Frontend | React 18, Next.js 14,<br>TypeScript | user interface |
| 6 | KnowledgeCenter | Go 1.22, Gin,<br>PostgreSQL 16, RabbitMQ | learning tracks, progress,<br>dev recommendations |

## 4. Service communication

| Source | Destination | Protocol | Purpose |
| --- | --- | --- | --- |
| Frontend | ResearcherCrm | REST | user interaction |
| Frontend | Vacancies | REST | view vacancies |
| ResearcherCrm | KnowledgeCenter | RabbitMQ | learning plan |
| Vacancies | ResearcherCrm | RabbitMQ | vacancy events |
| Parsing&AIConnector | Vacancies | RabbitMQ | import vacancies |
| ResearcherCrm | Parsing&AIConnector | RabbitMQ | AI requests |
| KnowledgeCenter | ResearcherCrm | RabbitMQ | learning recommendations |

## 5. Bounded Contexts

| Context | Service |
| --- | --- |
| Vacancy Management | Vacancies |
| Job Search & Management | ResearcherCrm |
| AI & Parsing | Parsing&AIConnector |
| Learning Management | KnowledgeCenter |

Detailed boundary descriptions: `/docs/domain/bounded-contexts/`.

## 6. Search Architecture

For full‑text search we use **OpenSearch / Elasticsearch**. Direct full‑text
queries to PostgreSQL are forbidden.

- **Vacancy Search:** full‑text, filters (employer, salary, location, status)
- **Employer Search:** by name, website, active vacancies
- **Skills Search:** autocomplete for desired job

Indexing happens asynchronously via RabbitMQ events (`VacancyImported`,
`VacancyUpdated`, `VacancyClosed`, `EmployerImported`). Cluster of ≥3 nodes,
daily index backup.

More about search engine choice – [ADR-014](./adr/adr-014-opensearch.md).

## 7. External integrations and Anti‑Corruption Layer (ACL)

| External system | ACL located in | Tasks |
| --- | --- | --- |
| Job portals (LinkedIn, Djinni) | Parsing&AIConnector | parse HTML/JSON, normalise,<br>map to domain |
| AI providers (OpenAI, Ollama) | Parsing&AIConnector | unify prompts, error handling,<br>fallback |
| Google Calendar | ResearcherCrm (async) | create events, OAuth |
| Google OAuth2 | authentication module | token verification, role mapping |

**ACL principles:** no business logic, own tests, changes in external APIs do
not affect the domain.

ACL details are described in [ADR-015](./adr/adr-015-acl.md).

## 8. Cross‑functional architectural principles

### 8.1 Clean Architecture

All services follow Clean Architecture: layers **Presentation → Application →
Domain → Infrastructure**.

### 8.2 Test‑Driven Development (TDD)

Testing priority: Domain Layer → Application Layer → Integration Layer →
Acceptance Layer. Red‑Green‑Refactor. Every business rule must have a test.

### 8.3 Event‑Driven Architecture

Main inter‑service communication is through events (RabbitMQ). Reasons: high
scalability, loose coupling, fault tolerance, asynchronous processing.

### 8.4 Event Versioning Policy

Each event contains `event_version`. Breaking changes increase the version; the
old version is published in parallel for at least 30 days.

**Message format example:**

    {
      "event_id": "uuid",
      "event_type": "ReplyCreated",
      "event_version": 1,
      "aggregate_id": "reply-123",
      "timestamp": "2025-02-24T10:00:00Z",
      "correlation_id": "xxx",
      "data": { ... }
    }

**Compatibility rules:**

- **Backward compatible:** adding optional field, extending enum – version
  unchanged.
- **Forward compatible:** removing unused field – version unchanged.
- **Breaking change:** removing mandatory field, changing type, semantics –
  increase `event_version`, publish old version in parallel ≥30 days.

**Deprecation Policy:** deprecated version is supported for 30 days, then
publishing stops.

Versioning policy is fixed in [ADR-012](./adr/adr-012-event-versioning.md).

### 8.5 Idempotency Strategy

To prevent duplicate processing of events and requests, a combination of
mechanisms is used:

- **Idempotency-Key** for synchronous APIs: client generates a unique key,
  service stores it for 7 days and returns cached response on repeat.
- **Deduplication by `event_id`** for asynchronous consumers: each event has a
  unique `event_id`. Consumer checks if it has already been processed.
- **`processed_events` table** (`event_id` PK) in each DB. Before processing an
  event, insert; if duplicate, ignore.
- Table cleaned daily (TTL 7 days).

**Example for ReplyCreated:**

    BEGIN;
    INSERT INTO processed_events (event_id, event_type, processed_at)
    VALUES ('evt_12345', 'ReplyCreated', NOW());
    -- then business logic to create Reply
    COMMIT;

Idempotency strategy is described in [ADR-013](./adr/adr-013-idempotency.md).

### 8.6 Outbox Pattern

For reliable event publication we use transactional outbox:

- Table `outbox_messages` in each service’s DB.
- In the same transaction as aggregate save, the service writes the event to
  outbox.
- A separate publisher reads outbox, sends to RabbitMQ, marks published.
- Consumers must be idempotent.

Details – [ADR-011](./adr/adr-011-outbox-pattern.md).

## 9. Documentation and contracts (Documentation as Code)

- All documentation in the `/docs` repository.
- **API specifications:** OpenAPI 3.0, generated in CI, published to
  `docs/api/<service>/`.
- **BDD scenarios:** Gherkin in `docs/features/<service>/`, run in CI.
- **C4 diagrams:** in `/docs/c4/`.
- **Main registry:** `/docs/README.md`.
- **ADR:** in `/docs/adr/`.

CI rejects changes without updating specifications and passing tests.

## 10. CI/CD and contract publication

CI pipeline (`.github/workflows/ci.yml`):

1. **Testing:** unit + integration + BDD (by cloning `docs` repo).
2. **OpenAPI/AsyncAPI publication:** via Deploy Key to `docs/api/`.

**Run BDD tests locally:**

    git clone https://github.com/AIJobResearcher/docs.git ../docs
    cd <service-dir>
    vendor/bin/behat   # for PHP
    # or behave (Python), godog (Go)

Filter: `vendor/bin/behat --tags @interview`

## 11. Links to detailed artifacts

- **ADR:** `./adr/`
- **C4 diagrams:** `/docs/c4/`
- **Bounded Context Canvas:** `/docs/domain/bounded-contexts/`
- **Event Storming:** `/docs/event-storming/`
- **Domain Model:** `./domain/domain-model.md`
- **AI & RAG Pipeline:** `./domain/ai-rag-pipeline.md`
- **Technical Requirements:** `./technical-requirements.md`
