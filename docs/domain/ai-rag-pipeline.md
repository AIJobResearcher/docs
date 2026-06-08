# AI & RAG Pipeline for AIJobResearcher

**Version:** 1.0

> **Related documentation:** [Glossary](../glossary.md) |
> [Architecture Overview](../architecture-overview.md) |
> [Technical Requirements](../technical-requirements.md) |
> [Domain Model](domain-model.md) | [README](../README.md)

## 1. Introduction

This document describes the technical details of AI recommendations and external
portal parsing in the `Parsing&AIConnector` service. Business scenarios and
domain events related to AI and parsing are in
[Domain Model (section 1.3)](domain-model.md). Architectural decisions (broker
choice, ACL, event versioning) are in
[Architecture Overview](../architecture-overview.md).

## 2. AI model integration strategy (ADR‑006)

**Interface:** `AIProviderInterface` with method
`generateRecommendations(prompt)`.

**Implementations:**

- `OllamaAIProvider` – local model `llama3.2` (free, for development and demo).
- `OpenAIProvider` – `gpt-3.5-turbo` (paid, requires API key).

**Budget management:** `OpenAIProvider` has monthly token limits. When exceeded
– automatically switch to `OllamaAIProvider` (if available) or return an error
message.

**Caching:** all AI requests are cached in Redis for 24 hours (for
recommendations) and 7 days (for learning plans). Cache key is prompt hash.
Cache invalidated by `VacancyUpdated` event.

**Asynchrony:** user request is placed in a RabbitMQ queue, processed by a
Celery worker, result returned via polling or WebSocket.

## 3. External portal parsing (ADR‑007)

**Modes:**

- Full scan – once per day.
- Incremental – once per hour (only vacancies updated in the last 24 hours).

**Ethics and limits:**

- Read `robots.txt`, respect `Crawl‑delay`.
- User‑Agent: `AIJobResearcher/1.0 (contact@example.com)`.
- Proxy rotation on 403/429 errors, exponential backoff (1s, 2s, 4s, max 60s).
- Max 2 simultaneous connections to one host.

**Demo mode:** `ParsingMockClient` with fixtures (switch by
`PARSER_MODE=live`).

**Parsing configuration as code:** selectors and rules in YAML
(`docs/configs/parsers/`). Changes via PR, automatic smoke tests in CI.

**Broken structure detector:** before parsing, a test request; if the number of
found elements differs from the expected by more than N%, parsing aborts with a
notification.

**Monitoring:** metrics `parsing_success_rate`, `parsing_validation_errors`.
Alert when `success_rate < 0.8` for 5 minutes.

## 4. RAG Pipeline (Retrieval‑Augmented Generation)

RAG is used to generate recommendations for vacancies, resume improvement,
interview preparation, and summaries.

### 4.1 Document Processing

Source documents (vacancies, job seeker profiles, articles, interview logs)
undergo:

- Text extraction from HTML/PDF/JSON (BeautifulSoup, tika‑python).
- Cleaning, whitespace normalisation.
- Optional case folding.
- Stop word filtering.

### 4.2 Chunking Strategy

- **Chunk size:** 500 tokens (approx 350–400 words).
- **Overlap:** 50 tokens.
- **Strategy:** by paragraphs, with sentence boundaries (NLTK/spaCy).
- Short documents – one chunk.

### 4.3 Embeddings

- **For development:** `all-MiniLM-L6-v2` (384 dim).
- **For production:** `intfloat/e5-large-v2` (1024 dim).
- Embeddings generated asynchronously when document is added/updated.

### 4.4 Vector Database

**Chosen: Qdrant (self‑hosted).**  
Reasons: easy deployment, high CPU search performance, metadata filtering,
official Python client.

**Indexing:** each chunk stored with vector and metadata (`document_id`,
`type`, `vacancy_id`, `researcher_id`).

### 4.5 Retrieval

- User query → embedding.
- Search for `k` nearest neighbours (k=5 for recommendations, k=10 for complex
  queries).
- Filter by metadata (e.g., `researcher_id`).
- Distance – cosine, relevance threshold ≥ 0.75.

### 4.6 Prompt Templates

Templates stored in YAML files (`docs/prompts/`). Example for resume
improvement:

    You are a career consulting expert. Below are fragments from vacancy
    requirements and the job seeker’s profile.
    Use them to give recommendations for improving the resume. The answer
    should be structured: a list of concrete actions.

    --- Context ---
    {context}

    --- Job seeker’s query ---
    {query}

    --- Recommendations ---

### 4.7 Context Assembly

- Chunks sorted by score.
- Context length limit: 3000 tokens (for `gpt-3.5-turbo`) or 8000 tokens (for
  `llama3.2`).
- If exceeded – drop least relevant chunks.
- Add `timestamp` and `session_id` for debugging.

### 4.8 Integration with domains

- On `VacancyImported` event – vacancy text indexed in Qdrant.
- On `ResearcherUpdated` event – resume indexed.
- `KnowledgeCenter` can request summary generation via Parsing&AIConnector
  (sync or async).
- All AI requests from Researcher CRM go through RAG for context augmentation.

## 5. Monitoring and alerts

**Metrics (Prometheus):**

- `rag_search_latency_seconds` – Qdrant search latency.
- `rag_chunks_retrieved` – number of retrieved chunks.
- `rag_context_length_tokens` – assembled context length.
- `ai_provider_requests_total` – requests to OpenAI/Ollama.
- `ai_provider_errors_total` – AI errors.
- `parsing_success_rate`, `parsing_validation_errors`.

**Alerts:**

- Average chunks retrieved < 2 for 10 minutes → vectorisation problem.
- `ai_provider_errors_total` > 5% for 5 minutes → critical.
- `parsing_success_rate` < 0.8 for 5 minutes → warning.

## 6. Fallback and fault tolerance

- If Qdrant unavailable – search disabled, prompt used without context.
- On OpenAI error – automatic retry (3 attempts), then fallback to Ollama or
  user message.
- On OpenAI budget exceeded – switch to Ollama + notify administrator.

## 7. Related ADRs

- [ADR‑006: AI model integration strategy](../adr/adr-006-ai-integration.md)
- [ADR‑007: External portal parsing strategy](../adr/adr-007-parsing-strategy.md)
- [ADR‑010: Qdrant choice and RAG strategy](../adr/adr-010-qdrant-rag.md)

*Implementation details not described here can be found in the code of the
`Parsing&AIConnector` service and its CI configurations.*
