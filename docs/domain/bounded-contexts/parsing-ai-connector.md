# Bounded Context: AI & Parsing (Parsing&AIConnector Service)

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [README](../../README.md)

## Responsibility

Integration with AI models to generate recommendations, parse external portals,
enrich and deduplicate vacancy data, cache results, RAG pipeline.

## Key NFRs

- Asynchronous AI request processing (p95 ≤ 2 s)
- Caching (24h for recommendations, 7 days for learning plans)
- Fault tolerance during portal parsing blockages

## Business processes

- Generate vacancy recommendations (sync on request and async push notifications)
- Generate resume improvement recommendations
- Generate search strategy recommendations
- Generate interview preparation recommendations
- Generate AI summaries for learning (on KnowledgeCenter request)
- Parse portals with automatic recovery
- Normalize source data and use AI-assisted matching to decide catalogue
  creates, updates, merges and closures

## User stories

1. **Vacancy recommendations**

   - As a job seeker, I want to receive AI recommendations for vacancies that best
     match my profile and desired jobs, so I don’t waste time on manual search.

2. **Resume recommendations**

   - As a job seeker, I want to receive AI recommendations for improving my resume
     based on analysis of target vacancy requirements and my past experience.

3. **Search strategy recommendations**

   - As a system, I want to provide the job seeker with AI recommendations for job
     search strategy (e.g., which vacancies are more priority, how to apply, how
     to communicate with interviewers).

4. **Interview preparation**

   - As a job seeker, I want to receive AI recommendations for preparing for a
     specific interview (typical questions, topics to review).

5. **Generate summaries for learning**

   - As KnowledgeCenter, I request generation of a short summary on a specific
     topic (set of questions) to include in the learning plan.

6. **Parse portals**

   - As a system, I want to automatically (on schedule) parse external job portals,
     respecting `robots.txt` and frequency limits, to keep the Vacancies Market service
     filled with fresh data.
   - As a system, I want to automatically monitor parsing success and when it drops
     below the threshold (80%) – suspend activity for a set interval (30 minutes),
     then resume, to avoid blocks and reduce load on the problematic portal.

## Business invariants

- All AI requests are cached in Redis for 24 hours (for recommendations) and 7 days
  (for learning plans) for the same prompt.
- If an external AI provider is unavailable or budget exceeded, the system returns
  the message “AI temporarily unavailable, please try later” and logs the error.
- Parsing must respect ethical norms: honour `robots.txt`, `Crawl‑delay`, use an
  identifiable User‑Agent.
- When parsing success rate is below 80% in the last 5 minutes, the system pauses
  parsing for 30 minutes, then automatically resumes. If the success rate again
  drops below 80% after resumption – a critical alert is generated, parsing
  continues with increased delay between requests.
- This context is the sole owner of requirement normalization, source matching
  and duplicate/merge decisions. It must include the decision, confidence and
  source provenance in each `CatalogueChangeRequested` command.

## Domain events

- `RecommendationGenerated` – for KnowledgeCenter
- `ParsingFailed` – alert
- `ExternalPortalUnreachable` – portal is unavailable during parsing
- `AITokenBudgetExceeded` – warning
- `ParsingSuspended` – on automatic suspension

## Integration command for Vacancy Management

After parsing, normalization and AI-assisted duplicate resolution, this context
publishes a `CatalogueChangeRequested` command over RabbitMQ for
`Vacancies Market`. The command contains one selected mutation:
`create`, `update`, `merge` or `close`.

It includes the target vacancy ID and expected version where applicable, the
complete canonical data, source provenance, duplicate IDs to merge, confidence
and the decision rationale. `Vacancies Market` validates and persists this
decision atomically; it does not repeat matching or merge selection.

To make decisions without accessing another service's database,
`Parsing&AIConnector` maintains a local catalogue projection by consuming
`Vacancies Market` events such as `VacancyImported`, `VacancyUpdated`,
`VacancyMerged` and `VacancyClosed`.

## RAG Pipeline (short)

- Document Processing (extract text from vacancies, resumes, articles)
- Chunking: 500 tokens, overlap 50
- Embeddings: `all-MiniLM-L6-v2` (dev) / `intfloat/e5-large-v2` (prod)
- Vector DB: Qdrant (self‑hosted)
- Retrieval: k=5–10, cosine distance, threshold 0.75
- Prompt templates in YAML
- Context Assembly (up to 3000 tokens for gpt-3.5-turbo)

## Aggregates and entities

### ParsingTask

- Fields: `id`, `portal_id`, `type` (vacancy/employer/interviewer), `last_run_at`,
  `status` (pending/running/completed/failed), `error_log`, `retry_count`

### AIRecommendationTask

- Fields: `id`, `type`, `input_prompt`, `response` (JSON), `status`, `created_at`,
  `completed_at`

### VacancyCandidate (internal entity)

- Fields: `id`, `source_key`, `external_vacancy_id`, `raw_payload`,
  `normalized_payload`, `candidate_vacancy_ids`, `similarity_scores`,
  `decision` (create/update/merge/close), `decision_rationale`, `status`,
  `created_at`, `decided_at`
- Behaviour: `normalize()`, `findDuplicateCandidates()`, `selectMutation()`,
  `requestCatalogueChange()`

### AIModel (lookup)

- Fields: `id`, `name`, `version`, `endpoint`, `input_schema`, `output_schema`,
  `prompt_preconditions`, `is_default`

## Interaction with other contexts

- **Downstream:** Vacancies Market (supplies approved catalogue-change commands)
- **Downstream:** Researcher CRM (AI recommendations)
- **Downstream:** KnowledgeCenter (generate summaries)
- **Upstream:** External portals (LinkedIn, Djinni) and AI providers (OpenAI, Ollama)

## Implementation

- Service: `Parsing&AIConnector`
- Technologies: Python 3.12, FastAPI, Celery, RabbitMQ
