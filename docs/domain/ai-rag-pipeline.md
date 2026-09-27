# AI & RAG Pipeline for AIJobResearcher

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.1

> **Related documentation:** [Glossary](../glossary.md) |
> [Parsing&AIConnector](./bounded-contexts/parsing-ai-connector.md) |
> [ADR‑006](../adr/adr-006-ai-integration.md) |
> [ADR‑007](../adr/adr-007-parsing-strategy.md) |
> [ADR‑010](../adr/adr-010-qdrant-rag.md) |
> [Technical Requirements](../technical-requirements.md) |
> [Architecture Overview](../architecture-overview.md) | [README](../README.md)

## 1. Introduction

This document describes the flow of the Retrieval‑Augmented Generation (RAG)
pipeline of the `Parsing&AIConnector` service: how documents are prepared,
indexed, retrieved and assembled into a prompt.

The decisions behind the pipeline are recorded separately, and their parameters
are not repeated here:

- AI model providers, caching and budget fallback – ADR‑006.
- External portal parsing (modes, ethics, limits, broken structure detector) –
  ADR‑007.
- Vector database, embedding models, chunk sizes, search parameters and context
  limits – ADR‑010.
- Metrics, alerts and SLO – Technical Requirements §5.3.

## 2. RAG Pipeline

### 2.1 Document processing

Source documents (vacancies, job seeker profiles, articles, interview logs)
undergo:

- Text extraction from HTML/PDF/JSON (BeautifulSoup, tika‑python).
- Cleaning, whitespace normalisation.
- Optional case folding.
- Stop word filtering.

### 2.2 Chunking

- Strategy: by paragraphs, with sentence boundaries (NLTK/spaCy).
- Short documents form a single chunk.
- Chunk size and overlap – ADR‑010.

### 2.3 Embeddings

- Generated asynchronously when a document is added or updated.
- Models for development and production – ADR‑010.

### 2.4 Vector database

- **Qdrant (self‑hosted)** – rationale and deployment – ADR‑010.
- Each chunk is stored with its vector and metadata: `document_id`, `type`,
  `vacancy_id`, `researcher_id`.

### 2.5 Retrieval

- User query → embedding.
- k‑nearest neighbours search with metadata filtering (e.g. by
  `researcher_id`).
- Distance, k values and relevance threshold – ADR‑010.

### 2.6 Prompt templates

Templates are stored as YAML files in the service repository. Example for resume
improvement:

```text
You are a career consulting expert. Below are fragments from vacancy
requirements and the job seeker’s profile.
Use them to give recommendations for improving the resume. The answer
should be structured: a list of concrete actions.

--- Context ---
{context}

--- Job seeker’s query ---
{query}

--- Recommendations ---
```

### 2.7 Context assembly

- Chunks are sorted by score; the least relevant chunks are dropped when the
  context limit is exceeded (limit – ADR‑010).
- `timestamp` and `session_id` are added for debugging.
