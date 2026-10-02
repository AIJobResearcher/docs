# ADR-007: External Portal Parsing Strategy

**Status:** accepted
**Date:** 2026-09-30

## Context

Vacancies, employers, and interviewers are imported from external portals
(LinkedIn, Djinni, etc.). We need to update data regularly, respect ethics
(robots.txt, Crawl‑delay), and robustly handle changes in portal structure.

## Decision

- **Modes:** incremental runs on the per-portal watch interval (minute tick for
  the hottest portals); full scans once a day.
- **Sources (phase 1):** LinkedIn, Djinni, rabota.ua, work.ua, dou.ua;
  RSS/API endpoints are used before any HTML scraping.
- **Ethics:** read `robots.txt`, respect `Crawl‑delay`, User‑Agent
  `AIJobResearcher/1.0 (contact@example.com)`.
- **Rate limiting:** one shared Redis limiter per host across all workers and
  proxies; limit 2 connections per host.
- **Anti‑blocking:** proxy rotation on 403/429, exponential backoff (1s, 2s, 4s,
  max 60s); a detected ban pauses that portal watch and raises an alert.
- **JavaScript pages:** Playwright only where the page needs JavaScript;
  Crawlee for Python (or Scrapy) for full crawls.
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
- Automatic recovery keeps manual intervention by the team rare.

## Alternatives

- Manual import via CSV/API – not automated, does not scale.
- Using third‑party vacancy aggregators (e.g., Adzuna) – paid, not for demo.

## Consequences

- Monitor metrics `parsing_success_rate`, `parsing_validation_errors`,
  `parsing_records_total{portal}`, `parser_rate_limit_throttled_total`. Alert on
  403/429 responses and on a ban signature per portal.
- On parsing failure, an engineer fixes the YAML and opens a PR; CI runs tests.
- Production requires a pool of proxy servers (configured via environment
  variables).
- LinkedIn is the riskiest source: a ToS change or an account ban removes it,
  so the parser prefers its public RSS/API surface and pauses on 403/429.

## Related artifacts

- ADR-006 (AI models) – part of parsing is used for AI recommendations.
- ADR-022 (service stack: httpx, Playwright, Crawlee, Redis limiter).
- Parsing context: `docs/domain/bounded-contexts/parsing-ai-connector.md`.
