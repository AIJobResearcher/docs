# ADR-010: Choosing Qdrant and the RAG Strategy for AI Recommendations

## Context

To generate high‑quality AI recommendations (for vacancies, resume improvement,
interview preparation) we need contextual information from the knowledge base
(vacancies, resumes, articles). Without RAG, AI answers will be too generic.

## Decision

We use the Retrieval‑Augmented Generation (RAG) approach with the following
components:

- **Vector DB:** Qdrant (self‑hosted).
- **Embedding model:** `all-MiniLM-L6-v2` (development) / `intfloat/e5-large-v2`
  (production).
- **Chunking:** 500 tokens, overlap 50.
- **Search:** k‑nearest neighbours (k=5–10), cosine distance, threshold ≥ 0.75.
- **Prompt templates** in YAML, **context assembly** truncating to 3000 tokens
  (for `gpt-3.5-turbo`).

Why Qdrant:

- Simple deployment (single Docker container, no external dependencies).
- High performance for vector search on CPU (enough for 20k RPS).
- Metadata filtering (important for isolation by `researcher_id` and document
  type).
- Official Python client (Parsing&AIConnector is written in Python).
- Free, open source.

## Why not other solutions

- **Elasticsearch with vectors** – supports dense vectors but requires extra setup
  and plugins; CPU search performance is lower.
- **Pinecone** – paid, vendor lock‑in.
- **Milvus** – powerful but complex to install (needs etcd, MinIO).
- **FAISS** – library only, no network API or real‑time index update mechanism.

## Consequences

- Adds a Qdrant component to the infrastructure (monitor its resources).
- When changing the embedding model, indexes must be rebuilt.
- Vector storage size grows as vacancies are added – accounted for in ADR-009.
- If Qdrant is unavailable, AI answers are returned without context (fallback).

## Related artifacts

- Section "RAG Pipeline" in `ai-rag-pipeline.md`.
- ADR-006 (AI models).
- Qdrant configuration in Docker Compose and Kubernetes manifests.
