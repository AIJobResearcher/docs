# ADR-014: Choosing OpenSearch / Elasticsearch for Full‑Text Search

**Status:** accepted
**Date:** 2026-09-27

## Context

With a load of 50k concurrent users and 20k RPS, direct full‑text queries to
PostgreSQL cannot meet the required SLO (p95 ≤ 300 ms). We need a specialised
search engine.

## Decision

We use **OpenSearch** (or Elasticsearch). Main search areas:

- **Vacancies** – full‑text search, filters (employer, salary, location,
  status), sorting.
- **Employers** – by name, website, active vacancies.
- **Skills** – autocomplete for the desired job.

Indexing is asynchronous via RabbitMQ events. Cluster of ≥3 nodes, daily index
backup.

Direct full‑text queries to PostgreSQL are forbidden: the search index is the
only full‑text path, and PostgreSQL keeps the write model only.

## Why this decision

- Performance at large volumes (millions of documents).
- Rich filtering and aggregation capabilities.
- Supports Lucene syntax.
- Compatible with Kibana (OpenSearch Dashboards).
- Free, open source.

## Alternatives

- PostgreSQL full‑text search – cannot handle the load.
- Algolia / Meilisearch – paid, vendor lock‑in.
- Typesense – less popular, not ready for 20k RPS.

## Consequences

- Adds a new component (OpenSearch cluster) to the infrastructure.
- Must keep the index up to date (events + initial load).
- Memory and disk costs.

## Related artifacts

- ADR-009 (Capacity Planning).
