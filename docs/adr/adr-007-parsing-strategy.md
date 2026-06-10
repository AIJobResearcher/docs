# ADR-007: External Portal Parsing Strategy

## Context

Vacancies, employers, and interviewers are imported from external portals
(LinkedIn, Djinni, etc.). We need to update data regularly, respect ethics
(robots.txt, Crawl‑delay), and robustly handle changes in portal structure.

## Decision

- **Modes:** full scan – once a day; incremental – once an hour (only updates
  from the last 24 hours).
- **Ethics:** read `robots.txt`, respect `Crawl‑delay`, User‑Agent
  `AIJobResearcher/1.0 (contact@example.com)`.
- **Anti‑blocking:** proxy rotation on 403/429, exponential backoff (1s, 2s, 4s,
  max 60s), limit 2 connections per host.
- **Demo mode:** `ParsingMockClient` with fixtures (switch via
  `PARSER_MODE=live`).
- **Parsing configuration as code:** selectors and rules in YAML
  (`docs/configs/parsers/`). Changes via PR, smoke tests in CI.
- **Broken structure detector:** before parsing, a test request; if the number
  of found elements differs from the expected by more than N%, parsing aborts
  with a notification.

## Why this decision

- Keeps data fresh with minimal load on external portals.
- Configuration as code allows quick reaction to structure changes.
- Automatic recovery reduces manual intervention by the administrator.

## Alternatives

- Manual import via CSV/API – not automated, does not scale.
- Using third‑party vacancy aggregators (e.g., Adzuna) – paid, not for demo.

## Consequences

- Monitor metrics `parsing_success_rate`, `parsing_validation_errors`. Alert
  when `success_rate < 0.8` for 5 minutes.
- On parsing failure, administrator fixes YAML and creates a PR; CI runs tests.
- Production requires a pool of proxy servers (configured via environment
  variables).

## Related artifacts

- ADR-006 (AI models) – part of parsing is used for AI recommendations.
- Section "External portal parsing" in `ai-rag-pipeline.md`.
