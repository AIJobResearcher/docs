# UI Pages

**Status:** accepted
**Date:** 2026-09-18
**Version:** 1.1

> **Related documentation:** [Glossary](../glossary.md) |
> [UI Flows](./flows.md) |
> [ADR-019 Frontend Architecture](../adr/adr-019-frontend-architecture.md)

Index of the Frontend service pages with links to their specifications.
Audience: frontend engineers, QA and analytics.

## 1. Pages

| Page | Route | Specification | Status |
| --- | --- | --- | --- |
| Vacancies Market | `.../vacancies-market` | [vacancies-market.md](./vacancies-market.md) | accepted |

## 2. Conventions

- **2.1** One specification per route.
- **2.2** A specification covers route, access, purpose, blocks, API operations,
  states, behaviour and edge cases.
- **2.3** Cross-page and multi-step scenarios live in [flows.md](./flows.md).
- **2.4** Every page is reachable from the main menu and requires an
  authenticated [Researcher](../glossary.md) unless its specification says
  otherwise.

## 3. Related Documents

- [Vacancies Market](./vacancies-market.md)
- [UI Flows](./flows.md)
- [ADR-019 Frontend Architecture](../adr/adr-019-frontend-architecture.md)
- [Glossary](../glossary.md)
