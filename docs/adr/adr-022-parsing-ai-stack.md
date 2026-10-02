# ADR-022: Parsing&AIConnector Stack

**Status:** accepted
**Date:** 2026-09-30

## Context

The Parsing&AIConnector service parses external portals, schedules per-portal
watches, generates AI recommendations and runs the RAG pipeline. Earlier ADRs
described a stateless stack with a local Ollama model, BeautifulSoup,
sentence-transformers and a full-crawl-once-a-day schedule; the service now owns
durable state, an adaptive polling schedule and a commercial AI provider.

## Decision

- **Database:** PostgreSQL 18 with SQLAlchemy 2 and Alembic migrations; the
  service stores its aggregates and the parsing schedule itself, not only task
  results.
- **Scheduling:** Celery with Celery Beat (RedBeat, backed by Redis). A
  minute tick selects the due `PortalWatch` rows from PostgreSQL with
  `FOR UPDATE SKIP LOCKED`, so several beats or workers never run the same
  watch twice.
- **Generation:** the DeepSeek API (`deepseek-chat`, `deepseek-reasoner`)
  behind the `AIProviderInterface` port, with LiteLLM as the gateway so a
  fallback provider can be added without touching the domain; Ollama is
  removed. Embeddings come from an external API (provider TBD).
- **Vectors:** Qdrant with quantization, one embedding model for both indexing
  and queries.
- **Parsing:** `httpx` + `selectolax` for HTML/JSON, Playwright only for
  JavaScript-rendered pages, and Crawlee for Python (or Scrapy) for full
  crawls; one shared Redis rate limiter per host across all workers, plus a
  proxy service.
- **Sources (phase 1):** LinkedIn, Djinni, rabota.ua, work.ua, dou.ua, taking
  RSS/API endpoints before HTML.
- **Load:** hundreds of watched URLs, 15+ of them polled every minute.
- **Redis:** AI response cache (24 h / 7 d), locks, rate limiting, Celery
  result backend and RedBeat.
- **External providers** need a DPA, zero-retention and no-training terms, and
  pseudonymised payloads before anything is sent.

## Why this decision

- Watches, cursors and backoff are state, not requests: a database makes the
  minute schedule correct after a restart and lets workers claim work safely.
- A provider port with a gateway keeps model choice and fallback out of the
  domain layer, and DeepSeek removes local GPU operations from the demo and
  production environments.
- Quantized vectors and one embedding model keep the re-embedding cost and the
  index size bounded.
- RSS/API-first with a shared per-host limiter is the cheapest way to stay
  inside portal terms and rate limits while polling hundreds of URLs.

## Alternatives

- **Stateless service, schedule in Redis or cron** – rejected: no atomic claim
  of a watch, harder recovery and no durable run history.
- **Keep Ollama as the default provider** – rejected: local model quality and
  container cost, and the provider port already allows local models without
  making them the default.
- **Scrapy-only parsing** – rejected: Playwright and Crawlee cover the
  JavaScript and full-crawl cases with less custom code.
- **Self-hosted embedding model** – rejected: one external API keeps the image
  small; the provider is still open.
- **Per-worker rate limits** – rejected: workers would collectively exceed the
  portal limit.

## Consequences

- Two more stateful components to operate (PostgreSQL and Qdrant) and to size –
  ADR-009.
- Browser workers need a separate image built from the Playwright base and their
  own queue and autoscaling rule.
- AI and embeddings traffic leaves the platform: DPA, pseudonymisation and
  provider allow-list are mandatory, and a fallback provider stays TBD.
- Changing the embedding model requires a staged re-index – ADR-010.

## Related artifacts

- [ADR-003](./adr-003-python-for-ai-parsing.md) (Python and libraries),
  [ADR-006](./adr-006-ai-integration.md) (AI providers),
  [ADR-007](./adr-007-parsing-strategy.md) (parsing),
  [ADR-009](./adr-009-capacity-planning.md) (capacity),
  [ADR-010](./adr-010-qdrant-rag.md) (Qdrant and RAG),
  [ADR-015](./adr-015-acl.md) (ACL).
- Bounded context:
  [AI & Parsing](../domain/bounded-contexts/parsing-ai-connector.md);
  pipeline: [AI & RAG](../domain/ai-rag-pipeline.md).
