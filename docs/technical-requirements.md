# Technical Requirements for AIJobResearcher

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.13
**Target load:** 50,000 concurrent active users
**Application version:** v1.0

> **Related documentation:** [Glossary](glossary.md) |
> [Architecture Overview](architecture-overview.md) |
> [Context Map](context-map.md) | [README](./README.md)

## 1. Non‑Functional Requirements (NFR)

### 1.1 Performance and scalability

- **Concurrent users:** 50,000 sessions; **average RPS** ~10,000, **peak** up to
  20,000 (9:00–11:00 UTC+3, 2–3 hours).
- **Autoscaling (K8s HPA):** CPU 70% for all services; additionally
  ResearcherCrm by p99 latency (Prometheus adapter), Parsing&AIConnector by
  RabbitMQ queue depth.
- **Buffer:** minimum replicas cover the average load with a 30% buffer
  ([ADR-009](./adr/adr-009-capacity-planning.md)); resources per replica and
  minimum replica counts – §2.1.

### 1.2 Service Level Objectives – latency (p95 / p99)

Paths are relative to the API base URL
(`https://api.aijobresearcher.com/api/v1`).

| Service             | Operation                   | p95     | p99     | Note                                                                                             |
|---------------------|-----------------------------|---------|---------|--------------------------------------------------------------------------------------------------|
| Vacancies Market    | `QUERY /vacancies`          | 300 ms  | 600 ms  | full‑text search with filters; Redis caching                                                      |
| ResearcherCrm       | `POST /interviews/schedule` | 400 ms  | 800 ms  | interviewer availability check, aggregate save, event publish; Google Calendar – async            |
| Parsing&AIConnector | `POST /ai/recommendations`  | 2000 ms | 4000 ms | external AI providers                                                                             |
| KnowledgeCenter     | `GET /knowledge/plan`       | 500 ms  | 1000 ms | learning plan based on aggregated data                                                            |

- **Alerting:** p99 above target by 50% for 5 minutes – warning, by 100% –
  critical; Prometheus histograms with buckets covering these thresholds.
- **Frontend (Core Web Vitals, field data):** LCP p75 ≤ 2.5 s, INP p75 ≤ 200 ms,
  CLS p75 ≤ 0.1, TTFB p95 ≤ 500 ms.

### 1.3 Availability and reliability

| Component                            | SLA   |
|--------------------------------------|-------|
| Vacancies Market, ResearcherCrm      | 99.9% |
| Parsing&AIConnector, KnowledgeCenter | 99.5% |
| RabbitMQ (infrastructure)            | 99.9% |

- **RTO / RPO:** Vacancies Market and ResearcherCrm – RTO 1 h, RPO 0
  (synchronous PostgreSQL replication, auto‑failover); Parsing&AIConnector and
  KnowledgeCenter – RTO 4 h, RPO 24 h (restore from backup); RabbitMQ – RTO 1 h,
  RPO 0 (mirrored queues, persistent messages).
- **Error budget:** 2% per hour – warning, 5% per hour – critical.
- **Failure tolerance:** peak of 20,000 RPS with no more than 2 nodes of each
  service failing.
- **Geo‑distribution:** single region; services are stateless, so multi‑region
  stays possible.

### 1.4 Consistency

- **Between services – eventual consistency:** p95 ≤ 2 s, p99 ≤ 5 s, alert at
  30 s (measured from publication to display in another service).
- **Inside a service – strong consistency:** local transactions only.

### 1.5 Accessibility and localisation

- **Accessibility:** WCAG 2.1 AA for all user-facing pages; criteria and
  component rules – `.ai-agent/standards/react-standards.md` §8.2.
- **Localisation:** English UI for now; user-facing strings stay keys so more
  locales can be added – the same standard, §8.3.

## 2. Capacity Planning

### 2.1 Compute resources (production)

| Service / Component            | CPU (cores) per replica | RAM (GB) | Min replicas            |
|--------------------------------|-------------------------|----------|-------------------------|
| Vacancies Market               | 2                       | 2        | 6                       |
| ResearcherCrm                  | 2                       | 2        | 6                       |
| Parsing&AIConnector            | 4                       | 8        | 4 + Celery workers      |
| KnowledgeCenter                | 1                       | 1        | 3                       |
| Frontend                       | 1                       | 2        | 3                       |
| PostgreSQL VacanciesMarket     | 4                       | 16       | 1 master + 2 replicas   |
| PostgreSQL ResearcherCrm       | 4                       | 16       | 1 master + 2 replicas   |
| PostgreSQL KnowledgeCenter     | 2                       | 8        | 1 master + 1 replica    |
| Redis (cache)                  | 2                       | 8        | 3 nodes (cluster)       |
| RabbitMQ                       | 2                       | 4        | 3 nodes                 |
| OpenSearch / Elasticsearch     | 4                       | 16       | 3 nodes (data + master) |

*Celery workers: 4 workers × 4 vCPU / 8 GB RAM.
*Demo environment: resources reduced 2–3 times.*

### 2.2 Data storage

| Database                     | Yearly growth     | Disk type | Min size       |
|------------------------------|-------------------|-----------|----------------|
| PostgreSQL Vacancies Market  | 50 GB             | SSD       | 200 GB         |
| PostgreSQL ResearcherCrm     | 100 GB            | SSD       | 300 GB         |
| PostgreSQL KnowledgeCenter   | 10 GB             | SSD       | 50 GB          |
| RabbitMQ (persistent queues) | 50 GB             | SSD       | 100 GB         |
| OpenSearch indexes           | 100 GB            | SSD       | 300 GB         |
| Redis (cache)                | 20 GB (in‑memory) | –         | limited by RAM |

### 2.3 Network resources

- Inter‑service traffic: ~500 Mbit/s average, up to 1 Gbit/s peak.
- External traffic (Frontend ↔ users): up to 200 Mbit/s.
- Latency inside the data centre: ≤ 1 ms (p99).

## 3. Security, authentication and audit

### 3.1 Authentication and authorization

- **Protocol:** OAuth2, JWT (RS256); access token 15 min, refresh token 7 days
  (httpOnly cookie).
- **SSO:** Google OAuth2.
- **Roles:** `Seeker` (in claims).
- **Inter‑service calls:** user JWT or system account token.

### 3.2 Encryption and personal data storage

- **Encryption:** AES‑256 at rest, TLS 1.3 in transit; keys from environment
  variables (demo) or HashiCorp Vault / cloud KMS (production).
- **GDPR:** `GET /researchers/{id}/export` (export) and
  `DELETE /researchers/{id}` (right to be forgotten) – see the
  [ResearcherCrm OpenAPI](./api/researcher-crm/openapi.yaml).
- **Pseudonymisation** for analytics and AI.
- **Retention:** 3 years from the last activity, then automatic
  archival/deletion.

### 3.3 Action audit

- Domain events → RabbitMQ → append‑only storage.
- Record: timestamp, `researcher_id`, action type, target object, context (IP,
  User‑Agent, session).
- Audit records are not exposed through the public API.

## 4. API Requirements

- **Specification:** OpenAPI 3.2.1 for every service; the specs are the single
  source of truth for their contracts (`docs/api/<service>/openapi.yaml`).
- **Conventions** (versioning, pagination, response codes, asynchronous
  operations, correlation ID, rate limiting):
  `.ai-agent/standards/yml-files-standards.md` §2.

## 5. Observability

### 5.1 Distributed tracing

- **OpenTelemetry SDK** → **Jaeger** (replaceable by Grafana Tempo).
- Traced: HTTP, RabbitMQ, DB, Redis, external APIs.

### 5.2 Logging

- **Format:** structured JSON to stdout, collected by **Promtail** →
  **Grafana Loki**; `trace_id` in every record.
- **Retention:** operational logs 7 days (demo) / 30 days (production); audit
  records 30 days / 1 year.

### 5.3 Metrics and alerts (Prometheus + Alert manager)

**Metrics:** `http_requests_total`, `http_request_duration_seconds`,
`rabbitmq_queue_messages`, `reply_event_processing_duration_seconds`,
`parsing_success_rate`, `parsing_validation_errors`,
`ai_recommendations_generated`, `rag_search_latency_seconds`,
`rag_chunks_retrieved`, `rag_context_length_tokens`,
`ai_provider_requests_total`, `ai_provider_errors_total`.

**Alerts:**

- RabbitMQ queue `ai_requests` > 10k messages (critical)
- Parsing errors > 20% for 5 minutes (warning)
- `ai_provider_errors_total` > 5% for 5 minutes (critical)
- Average chunks retrieved < 2 for 10 minutes (vectorisation problem)
- Latency and error‑budget alerts – §1.2 and §1.3

## 6. Performance Testing Plan

- **Scenarios:** read‑heavy (vacancy search – 90% of traffic), write‑heavy
  (replies and meetings), mixed with AI requests.
- **Environment:** staging with production replica counts and a smaller
  database.
- **Goal:** 50,000 concurrent users at SLO latency; 30% overload degrades
  gracefully instead of crashing.
- **Automation:** nightly run at 10% of the target load, results in
  Prometheus/Grafana.

## 7. Known Risks & Mitigations

| Risk                                       | Mitigation                                                            |
|--------------------------------------------|-----------------------------------------------------------------------|
| External job portal outage                 | Cache last successful data, alert, switch to backup source.           |
| AI model error (timeout, invalid response) | Retry with exponential backoff, fallback to keyword search – ADR-006. |
| Eventual consistency issues                | UI shows an asynchronous message; consistency SLO – §1.4.             |
| High memory usage in Python parsing        | Limit parallel workers, monitor, rotate IP via proxy.                 |
| HTML structure change on portal            | Configuration as code, broken structure detector – ADR-007.           |
| OpenAI budget exceeded                     | Monthly token limit, automatic switch to local Ollama – ADR-006.      |

## 8. Multi‑Tenancy (Logical data isolation for jobseekers)

The application serves individual jobseekers (B2C) in one shared region;
classical multi‑tenancy (separation between organizations) is not required, but
strict isolation between users is: a jobseeker reaches only their own profile,
replies, meetings, messages and learning plans.

### 8.1 Requirements

- Isolation is logical, by `researcher_id`; public catalogue data (vacancies,
  jobs, employers, interviewers, locations) is not user‑scoped.
- Every API request and event carrying personal data is checked against the
  `researcher_id` claim of the authenticated jobseeker; on mismatch the service
  returns `403 Forbidden`.
- The check lives in the Application Layer; the infrastructure layer cannot
  bypass it.
- Tests must prove that jobseeker A can neither read nor modify jobseeker B's
  data.
- Access attempts to another jobseeker's data are logged as
  `unauthorized_access_attempt`.
- Database indexes and cache keys are scoped by `researcher_id` (composite
  indexes; keys such as `recommendations:{researcher_id}:vacancy:{vacancy_id}`).
- Corporate multi‑tenancy is out of scope: a B2B model would need a separate
  architectural solution, likely a dedicated instance.

Logical isolation implementation – [ADR-016](./adr/adr-016-multitenancy.md).
