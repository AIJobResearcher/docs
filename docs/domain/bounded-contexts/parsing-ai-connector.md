# Bounded Context: AI & Parsing (Parsing&AIConnector Service)

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.4

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
> [ADR‑015: Anti‑Corruption Layer](../../adr/adr-015-acl.md)

## 1. Responsibility

- **1.1** Integrate with AI models to generate recommendations and summaries.
- **1.2** Parse external portals, enrich and deduplicate vacancy data; own
  requirement normalization and source matching.
- **1.3** Cache AI results and run the RAG pipeline.

## 2. Business processes and context boundary

- **2.1** Generate vacancy recommendations (synchronous on request and
  asynchronous push notifications).
- **2.2** Generate resume improvement recommendations.
- **2.3** Generate search strategy recommendations.
- **2.4** Generate interview preparation recommendations.
- **2.5** Generate AI summaries for learning (on KnowledgeCenter request).
- **2.6** Parse portals with automatic recovery.
- **2.7** Normalize source data and use AI‑assisted matching to decide catalogue
  creates, updates, merges and closures.
- **2.8** Boundary: the vacancy catalogue itself and the job seeker's data
  belong to other contexts; this context supplies AI results and approved
  catalogue decisions.

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
- **4.2.2** When the parsing success rate is below 80% in the last 5 minutes,
  parsing pauses for 30 minutes and then resumes automatically; a repeated drop
  raises a critical alert and parsing continues with a longer delay.

### 4.3 Catalogue decisions

- **4.3.1** This context is the sole owner of requirement normalization, source
  matching and duplicate/merge decisions.

## 5. Aggregates and entities

### 5.1 ParsingTask

- **5.1.1 Fields:** `id`, `portal_id`, `type` (vacancy/employer/interviewer),
  `last_run_at`, `status` (pending/running/completed/failed), `error_log`,
  `retry_count`.
- **5.1.2 Relationships:** references a `Portal` of Vacancy Management.
- **5.1.3 Behaviour:** scheduled runs with retry on failure.

### 5.2 AIRecommendationTask

- **5.2.1 Fields:** `id`, `type`, `input_prompt`, `response` (JSON), `status`,
  `created_at`, `completed_at`.
- **5.2.2 Relationships:** independent task aggregate; the resulting
  recommendation is stored by the requesting context (ResearcherCrm).
- **5.2.3 Behaviour:** asynchronous execution through the queue.

### 5.3 VacancyCandidate (internal entity)

- **5.3.1 Fields:** `id`, `source_key`, `external_vacancy_id`, `raw_payload`,
  `normalized_payload`, `candidate_vacancy_ids`, `similarity_scores`, `decision`
  (create/update/merge/close), `decision_rationale`, `status`, `created_at`,
  `decided_at`.
- **5.3.2 Relationships:** internal entity of this context; carries the
  normalized source record, duplicate candidates and the selected mutation.
- **5.3.3 Behaviour:** `normalize()`, `findDuplicateCandidates()`,
  `selectMutation()`, `requestCatalogueChange()`.

### 5.4 AIModel (lookup)

- **5.4.1 Fields:** `id`, `name`, `version`, `endpoint`, `input_schema`,
  `output_schema`, `prompt_preconditions`, `is_default`.
- **5.4.2 Relationships:** lookup entity of this context; AI tasks resolve the
  model through it.
- **5.4.3 Behaviour:** none — lookup entity.

## 6. Interaction with other contexts

All inbound and outbound relationships (types, protocols, messages, purposes):
[Context Map](../../context-map.md) §2; external systems (portals, AI providers)
– [ADR-015](../../adr/adr-015-acl.md).
