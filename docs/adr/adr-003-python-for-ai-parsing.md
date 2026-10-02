# ADR-003: Using Python for the Parsing & AI Service

**Status:** accepted
**Date:** 2026-09-30

## Context

The Parsing&AIConnector service is responsible for parsing external portals,
integrating with external AI providers (DeepSeek), and building the RAG
pipeline. We need a language with a rich ecosystem for these tasks.

## Decision

We chose **Python** with FastAPI (async handlers at the edge) and Celery
(asynchronous tasks). Key libraries: `httpx` + `selectolax` (HTML/JSON),
`tika` (PDF), LiteLLM with the DeepSeek client (generation), an external
embeddings API (provider TBD), Qdrant client (vector DB).

Supported versions are pinned in
[Architecture Overview §1](../architecture-overview.md).

## Why this decision

- Largest ecosystem for AI, NLP and parsing.
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
- ADR-022 (Parsing&AIConnector stack).
- Section "RAG Pipeline" in `docs/domain/ai-rag-pipeline.md`.
