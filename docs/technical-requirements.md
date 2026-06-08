<!-- markdownlint-disable MD013 -->

# Technical Requirements for AIJobResearcher

**Version:** 1.0
**Target load:** 50,000 concurrent active users
**Application version:** v1.0

---

> **Related documentation:** [Glossary](glossary.md) |
> [Architecture Overview](architecture-overview.md) | [README](./README.md)

## 1. Non‑Functional Requirements (NFR)

### 1.1 Performance and scalability

- **Concurrent users:** 50,000 sessions.
- **Average RPS (total):** ~10,000 requests per second.
- **Peak RPS:** up to 20,000 (9:00–11:00 UTC+3, duration 2–3 hours).
- **Horizontal scaling:** all services – at least 10 replicas.
- **Autoscaling (K8s HPA):**
  - CPU utilization 70% – for all services.
  - Additionally: Researcher CRM – by p99 latency (Prometheus adapter).
  - Parsing&AIConnector – by RabbitMQ queue depth.
- **Buffer:** minimum replicas for average load, maximum – double average
  RPS + 30%.

### 1.2 Service Level Objectives – latency (p95 / p99)

| Service             | Operation                                  | p95     | p99     | Note                                                                                            |
|---------------------|--------------------------------------------|---------|---------|-------------------------------------------------------------------------------------------------|
| Vacancies           | `GET /api/vacancies` (search with filters) | 300 ms  | 600 ms  | Redis caching                                                                                   |
| Researcher CRM      | `POST /api/interviews/schedule`            | 400 ms  | 800 ms  | includes interviewer availability check, aggregate save, event publish; Google Calendar – async |
| Parsing&AIConnector | `POST /api/ai/recommendations`             | 2000 ms | 4000 ms | external AI providers; alert on exceed                                                          |
| KnowledgeCenter     | `GET /api/knowledge/plan?userId={id}`      | 500 ms  | 1000 ms | learning plan based on aggregated data                                                          |

- **Metrics:** Prometheus histograms with buckets covering the stated thresholds.
- **Alerting:** when p99 exceeds target by 50% for 5 minutes – warning; by 100% –
  critical.

### 1.3 Availability and reliability

| Component                            | SLA   |
|--------------------------------------|-------|
| Vacancies, Researcher CRM            | 99.9% |
| Parsing&AIConnector, KnowledgeCenter | 99.5% |
| RabbitMQ (infrastructure)            | 99.9% |

#### RTO / RPO

- Vacancies, Researcher CRM: RTO = 1 hour, RPO = 0 (synchronous PostgreSQL
  replication, auto‑failover).
- Parsing&AIConnector, KnowledgeCenter: RTO = 4 hours, RPO = 24 hours (restore
  from backup).
- RabbitMQ: RTO = 1 hour, RPO = 0 (mirrored queues, persistent messages).

**Error budget:** monitor error budget consumption. 2% per hour → warning, 5% per
hour → critical.

**Geo‑distribution:** single region; stateless architecture ready for future
multi‑region.

### 1.4 Consistency

- **Eventual consistency:** allowed delay between services – p95 ≤ 2 sec, p99 ≤ 5
  sec, max window (alert) – 30 sec. Example: `ReplyCreated` event from
  publication to display in Researcher CRM analytics.
- **Strong consistency** – inside a single service via local transactions (Clean
  Architecture).

---

## 2. Capacity Planning

### 2.1 Compute resources (production)

| Service / Component          | CPU (cores) per replica | RAM (GB) | Min replicas            |
|------------------------------|-------------------------|----------|-------------------------|
| Vacancies (PHP/Laravel)      | 2                       | 2        | 6                       |
| ResearcherCrm (PHP/Symfony)  | 2                       | 2        | 6                       |
| Parsing&AIConnector (Python) | 4                       | 8        | 4 + Celery workers      |
| KnowledgeCenter (Go)         | 1                       | 1        | 3                       |
| Frontend (Next.js)           | 1                       | 2        | 3                       |
| PostgreSQL Vacancies         | 4                       | 16       | 1 master + 2 replicas   |
| PostgreSQL ResearcherCrm     | 4                       | 16       | 1 master + 2 replicas   |
| PostgreSQL KnowledgeCenter   | 2                       | 8        | 1 master + 1 replica    |
| Redis (cache)                | 2                       | 8        | 3 nodes (cluster)       |
| RabbitMQ                     | 2                       | 4        | 3 nodes                 |
| OpenSearch / Elasticsearch   | 4                       | 16       | 3 nodes (data + master) |

*Celery workers: 4 workers with 4 vCPU / 8 GB RAM each.
*Demo environment: reduce resources by 2–3 times.*

### 2.2 Data storage

| Database                     | Yearly growth     | Disk type | Min size       |
|------------------------------|-------------------|-----------|----------------|
| PostgreSQL Vacancies         | 50 GB             | SSD       | 200 GB         |
| PostgreSQL ResearcherCrm     | 100 GB            | SSD       | 300 GB         |
| PostgreSQL KnowledgeCenter   | 10 GB             | SSD       | 50 GB          |
| RabbitMQ (persistent queues) | 50 GB             | SSD       | 100 GB         |
| OpenSearch indexes           | 100 GB            | SSD       | 300 GB         |
| Redis (cache)                | 20 GB (in‑memory) | –         | limited by RAM |

### 2.3 Network resources

- Average traffic between services: ~500 Mbit/s (peak up to 1 Gbit/s).
- External traffic (Frontend ↔ users): up to 200 Mbit/s.
- Latency inside data center: ≤ 1 ms (p99).

### 2.4 Buffer and monitoring

- 30% buffer above calculated peak load.
- HPA triggers at 70% CPU.
- Peak of 20,000 RPS must be handled with no more than 2 nodes of each service
  failing.

---

## 3. Security, authentication and audit

### 3.1 Authentication and authorization

- **Protocol:** OAuth2, JWT (RS256).
- **Access token:** 15 min; **Refresh token:** 7 days (httpOnly cookie).
- **SSO:** Google OAuth2 (future: LinkedIn).
- **Roles:** Seeker, Interviewer, Employer, Admin (in claims).
- **Inter‑service call:** user JWT or system account token.

### 3.2 Encryption and personal data storage

- **Encryption:** AES‑256 at database level, TLS 1.3 in transit.
- **Keys:** demo – env, production – HashiCorp Vault / cloud KMS.
- **GDPR:** endpoints `DELETE /api/users/{id}` (right to be forgotten),
  `GET /api/users/{id}/export`.
- **Pseudonymisation** for analytics and AI.
- **Retention period:** 3 years from last activity, then automatic
  archival/deletion.

### 3.3 Action audit

- Audit via domain events → RabbitMQ → append‑only storage.
- Record: timestamp, user_id, action type, target object, context (IP,
  User‑Agent, session).
- Access only for Admin role.

---

## 4. API Requirements

- **Specification:** OpenAPI 3.0+.
- **Versioning:** `/api/v1/...`.
- **Pagination:** `limit` (max 100), `offset` / `page+per_page`. Sorting
  `sort=field:asc`.
- **Response codes:** 200, 201, 400, 401, 403, 404, 429, 500.
- **Async operations:** 202 Accepted + `Location: /tasks/{id}`.
- **Correlation‑ID:** mandatory in headers, forwarded to all calls and events.
- **Rate limiting:** 100 requests/min (authenticated), 10/min (unauthenticated).

---

## 5. Observability

### 5.1 Distributed tracing

- **OpenTelemetry SDK** → **Jaeger** (can be replaced by Grafana Tempo).
- Traced: HTTP, RabbitMQ, DB, Redis, external APIs.

### 5.2 Logging

- **Format:** structured JSON to stdout.
- **Collection:** Prom-tail → **Grafana Loki**.
- **Storage:** operational – 7 days (demo) / 30 days (production); audit – 30
  days / 1 year.
- **Correlation:** `trace_id` in logs.

### 5.3 Metrics and alerts (Prometheus + Alert manager)

**Metrics:**

- `http_requests_total`, `http_request_duration_seconds`
- `rabbitmq_queue_messages`, `reply_event_processing_duration_seconds`
- `parsing_success_rate`, `parsing_validation_errors`,
  `ai_recommendations_generated`

**Alerts:**

- High p95 latency > SLO threshold (warning)
- RabbitMQ queue `ai_requests` > 10k messages (critical)
- Parsing errors > 20% for 5 minutes (warning)
- Error budget consumption >2% per hour (warning), >5% per hour (critical)

---

## 6. Performance Testing Plan

- **Tool:** k6 (scripts in `/loadtests`).
- **Scenarios:**
  - Read‑heavy: search vacancies (90% traffic)
  - Write‑heavy: create replies and meetings
  - Mixed with AI requests
- **Environment:** staging (same replicas, smaller DB).
- **Goal:** 50k concurrent users, p95 latency as in SLO.
- **Stress test:** 30% overload → graceful degradation, not crash.
- **Automation:** nightly run with 10% of target load, results in
  Prometheus/Grafana.

---

## 7. Known Risks & Mitigations

| Risk                                       | Mitigation                                                                     |
|--------------------------------------------|--------------------------------------------------------------------------------|
| External job portal outage                 | Cache last successful data, alert, switch to backup source.                    |
| AI model error (timeout, invalid response) | Retry with exponential backoff, fallback – keyword search.                     |
| Eventual consistency issues                | UI shows async message; SLO delay <5 s.                                        |
| High memory usage in Python parsing        | Limit parallel workers, monitor, rotate IP via proxy.                          |
| HTML structure change on portal            | Configuration as code, broken structure detector, alert, manual update via PR. |
| OpenAI budget exceeded                     | Monthly token limit, automatic switch to local Ollama.                         |

---

## 8. Multi‑Tenancy (Logical data isolation for jobseekers)

The application is cloud‑based and serves only individual jobseekers (B2C).
Classical multi‑tenancy (separation between organizations) is not required.
However, strict data isolation between different users is necessary: each
jobseeker can access only their own profile, replies, meetings, messages and
learning plans.

### 8.1 Architectural solution

Use logical isolation through `tenant_id = researcher_id` in all tables
containing personal data. All queries to such data are automatically filtered by
the ID of the currently authenticated jobseeker. Direct access to other users'
data is not allowed via API or events.

### 8.2 Implementation

- In the `ResearcherCrm` service, each record (Researcher, Job, Reply, Meet,
  Message) contains a `researcher_id` field. This field is a foreign key to the
  Researcher table and serves as the natural `tenant_id`.
- In the `KnowledgeCenter` service, tables (LearningTrack, Progress) also contain
  `researcher_id`.
- In the `Vacancies` service, vacancy records are not tied to a specific
  jobseeker (public data). Therefore, the `researcher_id` field is absent – it is
  public information.
- All API endpoints that return personal data check that the `researcher_id` in
  the request path or body matches the JWT claim `researcher_id`. On mismatch,
  return 403 Forbidden.
- RabbitMQ events containing personal data include the `researcher_id` field.
  Consumers (e.g., KnowledgeCenter) use this field for access checking (if the
  event is user‑initiated) or for routing.

### 8.3 Security and audit

- Logical isolation is checked at the domain model level (Application Layer).
  The infrastructure layer cannot bypass the check.
- Tests must ensure that jobseeker A cannot read or modify jobseeker B's data.
- All attempts to access other users' data are logged in the audit log as a
  suspicious action (type `unauthorized_access_attempt`).

### 8.4 Scalability and performance

- Database indexes are built with filtering by `researcher_id` (composite
  indexes).
- For Redis cache, keys include `researcher_id` (e.g.,
  `recommendations:{researcher_id}:vacancy:{vacancy_id}`).
- Horizontal scaling requires no changes – each service works with its own DB,
  where `researcher_id` is used for sharding if needed in the future.

### 8.5 Absence of corporate multi‑tenancy

The system does not support separation by organizations (companies, HR agencies).
All jobseekers are equal and work in one shared space of vacancies. If B2B
model is needed in the future (e.g., for companies internal search), it will
require a separate architectural solution (likely a dedicated instance).

Logical isolation implementation is documented in
[ADR-016](./adr/adr-016-multitenancy.md).
