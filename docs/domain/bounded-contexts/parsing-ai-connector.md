# Bounded Context: AI & Parsing (Parsing&AIConnector Service)

**Status:** accepted
**Date:** 2026-09-30
**Version:** 1.13

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [Context Map](../../context-map.md) |
> [OpenAPI](../../api/parsing-ai-connector/openapi.yaml) |
> [AI & RAG Pipeline](../ai-rag-pipeline.md) |
> [AsyncAPI](../../asyncapi/events.yaml) |
> [Technical Requirements](../../technical-requirements.md) |
> [README](../../README.md)
>
> **Related ADRs:** [ADR‑003: Using Python for the Parsing & AI
> Service](../../adr/adr-003-python-for-ai-parsing.md) |
> [ADR‑006: AI Model Integration
> Strategy](../../adr/adr-006-ai-integration.md) |
> [ADR‑007: External Portal Parsing
> Strategy](../../adr/adr-007-parsing-strategy.md) |
> [ADR‑010: Choosing Qdrant and the RAG
> Strategy](../../adr/adr-010-qdrant-rag.md) |
> [ADR‑015: Anti‑Corruption Layer](../../adr/adr-015-acl.md) |
> [ADR‑021: Context Communication](../../adr/adr-021-context-communication.md)

## 1. Responsibility

- **1.1** Integrate with AI models to generate recommendations and summaries.
- **1.2** Parse external portals and deliver new and changed employer,
  vacancy-source and interviewer records to Vacancy Management.
- **1.3** Cache AI results and run the RAG pipeline.
- **1.4** Own the `Portal` registry and the per-portal connection settings used
  by parsing and by portal updates.

## 2. Business processes and context boundary

- **2.1** Generate vacancy recommendations (synchronous on request and
  asynchronous push notifications).
- **2.2** Generate resume improvement recommendations.
- **2.3** Generate search strategy recommendations.
- **2.4** Generate interview preparation recommendations.
- **2.5** Generate AI summaries for learning (on KnowledgeCenter request).
- **2.6** Parse portals with automatic recovery.
- **2.7** Deliver portal records to Vacancy Management, which normalizes them,
  matches duplicates and decides catalogue creates, updates, merges and
  closures.
- **2.8** Boundary: the vacancy catalogue itself and the job seeker's data
  belong to other contexts; this context supplies AI results and portal
  records.
- **2.9** Monitor portal updates: the parser requests the three monitoring URLs
  of each enabled portal (vacancies, employers, interviewers) at the configured
  interval, stores the fetched records and publishes an event per new or
  changed record to Vacancy Management, which owns matching and the catalogue
  decision.

## 3. User stories

- **3.1 Vacancy recommendations:** a job seeker receives AI recommendations for
  vacancies that match the profile and desired jobs.
- **3.2 Resume recommendations:** a job seeker receives recommendations for
  improving the resume, based on target vacancy requirements and past
  experience.
- **3.3 Search strategy recommendations:** the system gives AI recommendations
  on search strategy (priority vacancies, how to apply, how to communicate with
  interviewers).
- **3.4 Interview preparation:** a job seeker receives recommendations for
  preparing for a specific interview (typical questions, topics to review).
- **3.5 Summaries for learning:** KnowledgeCenter requests a short summary on a
  specific topic to include in the learning plan.
- **3.6 Parse portals:** the system parses external job portals on a schedule,
  respecting `robots.txt` and frequency limits, and suspends parsing for a set
  interval when the success rate drops below the threshold.
- **3.7 Monitor portal updates:** the system monitors Portals for new and
  changed Employers, Vacancies and Interviewers and sends that data to the
  Vacancies Market Service.
- **3.8 Update portal data:** upon request, the system updates Employers,
  Vacancies and Interviewers on Portals.

## 4. Business invariants

### 4.1 AI requests

- **4.1.1** All AI requests are cached in Redis for 24 hours (recommendations)
  and 7 days (learning plans) for the same prompt.
- **4.1.2** If an external AI provider is unavailable or its budget is exceeded,
  the system returns “AI temporarily unavailable, please try later” and logs the
  error.

### 4.2 Parsing

- **4.2.1** Parsing respects ethical norms: `robots.txt`, `Crawl‑delay` and an
  identifiable User‑Agent.

### 4.3 Portal

- **4.3.1** A Portal cannot be deleted while an active `PortalWatch` or a
  pending `PortalUpdateTask` references it; a `Source` of Vacancy Management
  keeps its `portal_id` as a historical reference.

## 5. Aggregates and entities

### 5.1 Portal (lookup)

- **5.1.1 Fields:** `id`, `code` (string, unique — portal key such as
  `linkedin`, `djinni`), `name` (string), `base_url` (string, nullable),
  `created_at`, `updated_at`.
- **5.1.2 Relationships:** lookup entity of this context; referenced by
  `PortalConnection`, `PortalWatch`, `ParsingTask` and `PortalUpdateTask`, and
  by `Source` of Vacancy Management by id.
- **5.1.3 Behaviour:** `createPortal()`, `updatePortal()`, `deletePortal()`.

### 5.2 PortalConnection (lookup)

- **5.2.1 Fields:** `id`, `portal_id`, `robots_policy` (JSON), `crawl_delay_s`,
  `rate_limit`, `credential_ref` (name of the environment variable that holds
  the token), `enabled`.
- **5.2.2 Relationships:** references a `Portal` of this context; shared by
  every watch and task of that portal.
- **5.2.3 Behaviour:** `allows(url)` evaluates `robots.txt` and the crawl
  delay; the record stores a credential reference, never a secret.

### 5.3 PortalWatch (aggregate)

- **5.3.1 Fields:** `id`, `portal_id`, `monitoring_urls` (`list<string>`,
  exactly three — vacancies, employers, interviewers), `cursor`,
  `last_polled_at`, `status` (active/paused), `suspended_until`.
- **5.3.2 Relationships:** references a `Portal` and its `PortalConnection`;
  one watch runs one `ParsingTask` per interval.
- **5.3.3 Behaviour:** `poll()` starts a run when the interval elapses and no
  run is active; `suspend()` and `resume()` pause and resume polling;
  `advanceCursor()`.

### 5.4 ParsingTask (aggregate)

- **5.4.1 Fields:** `id`, `watch_id`, `portal_id`, `started_at`, `finished_at`,
  `status` (pending/running/completed/failed), `urls_checked` (three),
  `records_seen`, `records_published`, `error_log`, `retry_count`.
- **5.4.2 Relationships:** one execution of a `PortalWatch`; references a
  `Portal`; produces `PortalSnapshot` records and outbound events.
- **5.4.3 Behaviour:** `fetch()` requests the three monitoring URLs and
  publishes one event per new or changed record; a failed run leaves the watch
  cursor unchanged, so the next run re-reads the same window.

### 5.5 PortalSnapshot (entity)

- **5.5.1 Fields:** `id`, `parsing_task_id`, `portal_id`, `entity_type`
  (source/employer/interviewer), `external_id`, `external_url`, `fetched_at`,
  `raw_payload`, `content_hash`, `changed`.
- **5.5.2 Relationships:** one record returned by a monitoring URL; carries the
  portal identity (`portal_id`, `external_id`) that Vacancy Management matches
  against the catalogue.
- **5.5.3 Behaviour:** `hash()` computes `content_hash`; an unchanged hash sets
  `changed` to false and suppresses the event.

### 5.6 PortalUpdateTask (aggregate)

- **5.6.1 Fields:** `id`, `portal_id`, `entity_type`
  (source/employer/interviewer), `external_refs` (JSON — the `external_id` of
  each requested entity), `desired_state` (JSON), `requested_by`,
  `status` (pending/running/completed/failed), `result`, `error_log`,
  `retry_count`, `created_at`, `completed_at`.
- **5.6.2 Relationships:** carries the catalogue-side references supplied by
  Vacancy Management, which owns `EntityMapping`; implements the outbound
  direction of 3.8 and never mutates the catalogue itself.
- **5.6.3 Behaviour:** `execute()` pushes the state to the portal and records a
  per-item result; retries transient portal errors, never a portal rejection.

### 5.7 AIRecommendationTask

- **5.7.1 Fields:** `id`, `type`, `input_prompt`, `response` (JSON), `status`,
  `created_at`, `completed_at`.
- **5.7.2 Relationships:** independent task aggregate; the resulting
  recommendation is stored by the requesting context (ResearcherCrm).
- **5.7.3 Behaviour:** asynchronous execution through the queue.

### 5.8 AIModel (lookup)

- **5.8.1 Fields:** `id`, `name`, `version`, `endpoint`, `input_schema`,
  `output_schema`, `prompt_preconditions`, `is_default`.
- **5.8.2 Relationships:** lookup entity of this context; AI tasks resolve the
  model through it.
- **5.8.3 Behaviour:** none — lookup entity.

## 6. Interaction with other contexts

All inbound and outbound relationships (types, protocols, messages, purposes):
[Context Map](../../context-map.md) §2; external systems (portals, AI providers)
– [ADR-015](../../adr/adr-015-acl.md).
