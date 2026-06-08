# ADR-006: AI Model Integration Strategy

## Context

The Parsing&AIConnector service generates recommendations for vacancies,
resumes, and interview preparation. We need a flexible integration with AI
models that works for free (for the demo) and with commercial APIs, while
controlling the budget.

## Decision

We created the `AIProviderInterface` with two implementations:

- **OllamaAIProvider** – local `llama3.2` model (runs in a container). Used by
  default, no cost.
- **OpenAIProvider** – `gpt-3.5-turbo`. Activated via environment variable
  `AI_PROVIDER=openai` and an API key.

Responses are cached in Redis (24 hours for recommendations, 7 days for learning
plans). When the OpenAI token limit is exceeded, the system automatically
switches to Ollama (logging the `AITokenBudgetExceeded` event).

## Why this decision

- Keeps the demo environment working when the OpenAI budget runs out.
- Allows developers to test AI features without extra cost (local model).
- A single interface makes it easy to add new providers (e.g., Google Gemini in
  the future).

## Alternatives

- Use only OpenAI – expensive for the demo, no offline capability.
- Use only a local model – lower recommendation quality, insufficient for an
  enterprise demo.

## Consequences

- Need to run Ollama in the infrastructure (added to Docker Compose
  configuration).
- Need to monitor OpenAI token usage and remaining budget.
- Cache is invalidated by the `VacancyUpdated` event (so recommendations consider
  new vacancies).

## Related artifacts

- ADR-010 (Qdrant and RAG).
- ADR-007 (portal parsing).
- Section "AI-RAG-Pipeline.md".
