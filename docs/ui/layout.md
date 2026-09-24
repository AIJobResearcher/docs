# UI Layout Specification: Page Header

**Status:** accepted
**Date:** 2026-09-18
**Version:** 1.2

> **Related documentation:** [Glossary](../glossary.md) |
> [UI Pages](./pages.md) | [UI Flows](./flows.md) |
> [ADR-019 Frontend Architecture](../adr/adr-019-frontend-architecture.md)

This document specifies the shared header rendered by the Frontend service on
every page. Audience: frontend engineers, QA and analytics.

## 1. Scope

- **1.1 Context:** the shell above every page registered in
  [UI Pages](./pages.md).
- **1.2 Out of scope:** page-specific blocks and pane layout, which stay in the
  page specification (e.g. [Vacancies Market](./vacancies-market.md)).
- **1.3 Source of truth:** this file for the header; API contracts stay in the
  OpenAPI specifications.

## 2. Header

- **2.1 Contents:** the logo and the Main menu (one link to Vacancies Market page).
- **2.2 Logo:** links to the home page; `alt` text required.
- **2.3 Placement:** above the page content and outside its scrolling panes.
- **2.4 Accessibility:** keyboard access, visible focus, contrast 4.5:1.
- **2.5 Localisation:** English UI; strings kept as keys for future locales.

## 3. Related Documents

- [UI Pages](./pages.md)
- [Vacancies Market](./vacancies-market.md)
- [UI Flows](./flows.md)
- [Glossary](../glossary.md)
