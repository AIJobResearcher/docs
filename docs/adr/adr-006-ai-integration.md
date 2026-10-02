# ADR-006: AI Model Integration Strategy

**Status:** accepted
**Date:** 2026-09-30

## Context

The Parsing&AIConnector service generates recommendations for vacancies,
resumes, interview preparation and learning summaries. The service needs one
integration point for commercial AI APIs, predictable cost, and a documented
behaviour when the provider is unavailable or the budget is exhausted.

## Decision

- **Provider:** the DeepSeek API — `deepseek-chat` for recommendations and
  `deepseek-reasoner` where reasoning quality matters.
- **Port:** all generation goes through `AIProviderInterface`; the LiteLLM
  gateway maps the port to DeepSeek, so a fallback provider is a configuration
  change, not a code change.
- **Fallback:** when DeepSeek is unavailable or the monthly budget is exceeded,
  the service uses the fallback provider (TBD) or returns a degraded
  "AI temporarily unavailable" answer, and logs the switch.
- **Caching:** responses are cached in Redis for 24 hours (recommendations) and
  7 days (learning plans) for the same prompt.
- **Removed:** the local Ollama model and `gpt-3.5-turbo` are out of the stack.
- Provider and credentials come from environment variables
  (`AI_PROVIDER=deepseek`, `DEEPSEEK_API_KEY`).

## Why this decision

- DeepSeek gives usable quality without running a local GPU model or a
  container per environment.
- One port plus a gateway keeps provider details out of the domain layer and
  turns the fallback provider into a deployment decision.
- Caching keeps a repeated prompt from spending budget twice.
- A single external provider makes the DPA, zero-retention and
  pseudonymisation requirements auditable in one place.

## Alternatives

- **Keep Ollama as the default** – rejected: local quality and container cost,
  while the port already allows a local provider later.
- **`gpt-3.5-turbo`** – rejected: superseded, and it duplicates what the
  DeepSeek API already covers.
- **Direct provider SDK calls in the domain** – rejected: no fallback and no
  substitution point for tests.
- **Several providers wired directly** – rejected: the gateway already covers
  routing and retries.

## Consequences

- A paid external dependency with a monthly budget to monitor; alerts cover
  provider errors and budget.
- Every prompt is pseudonymised before sending; provider allow-list and DPA are
  prerequisites, not options.
- Cache invalidation when the vacancy catalogue changes stays as before.
- The fallback provider is still TBD: until it is chosen, a DeepSeek outage
  degrades to the "AI temporarily unavailable" answer.

## Related artifacts

- ADR-003 (Python and libraries).
- ADR-007 (portal parsing).
- ADR-010 (Qdrant and RAG).
- ADR-022 (Parsing&AIConnector stack).
- Section "RAG Pipeline" in `docs/domain/ai-rag-pipeline.md`.
