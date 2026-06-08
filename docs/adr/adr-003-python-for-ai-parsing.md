# ADR-003: Using Python for the Parsing & AI Service

## Context

The Parsing&AIConnector service is responsible for parsing external portals,
integrating with AI models (OpenAI, Ollama), and building the RAG pipeline. We need
a language with a rich ecosystem for these tasks.

## Decision

We chose **Python 3.12** with FastAPI (synchronous endpoints) and Celery
(asynchronous tasks). Key libraries: BeautifulSoup, tika‑python (parsing),
sentence‑transformers (embeddings), Qdrant‑client (vector DB), openai (OpenAI
client).

## Why this decision

- Largest ecosystem for AI/NLP/parsing (spaCy, NLTK, transformers).
- Rapid prototyping and integration.
- Celery works well with RabbitMQ for async processing.
- FastAPI provides high performance and automatic OpenAPI generation.

## Alternatives

- Go – good performance, but AI ecosystem is much poorer.
- Java (Spring) – heavy, requires more code for parsing and AI.
- PHP – not suitable for heavy AI tasks.

## Consequences

- Need for a separate Celery worker.
- Managing Python dependencies (virtual environment, Docker).
- Less predictable memory usage (monitoring required).

## Related artifacts

- ADR-006 (AI models).
- ADR-007 (parsing).
- ADR-010 (Qdrant and RAG).
- Section "AI-RAG-Pipeline.md".
