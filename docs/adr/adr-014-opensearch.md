# ADR-014: Choosing OpenSearch / Elasticsearch for Full‑Text Search

## Context

With a load of 50k concurrent users and 20k RPS, direct full‑text queries to
PostgreSQL cannot meet the required SLO (p95 ≤ 300 ms). We need a specialised
search engine.

## Decision

We use **OpenSearch** (or Elasticsearch). Main search areas:

- Vacancies (full‑text, filters, sorting)
- Employers
- Skills

Indexing is asynchronous via RabbitMQ events (`VacancyImported`, `VacancyUpdated`,
etc.). Cluster of ≥3 nodes, daily index backup.

## Why OpenSearch

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

- Section "Search Architecture" in `architecture-overview.md`.
- ADR-009 (Capacity Planning).
