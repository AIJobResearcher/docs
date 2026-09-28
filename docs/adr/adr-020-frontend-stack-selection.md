# ADR-020: Frontend Stack Selection

**Status:** accepted
**Date:** 2026-09-28

## Context

The Frontend service renders the user interface over the backend APIs of
Vacancies Market and ResearcherCrm. It must serve authenticated, highly
interactive pages (vacancy list with tag filters and infinite scroll, details,
and later a dashboard with recommendations and statistics plus several
ResearcherCrm maintenance pages) and, in the near future, public pages that
must be indexed by search engines.

Binding requirements come from `docs/technical-requirements.md` (Core Web
Vitals, WCAG 2.1 AA, localisation with string keys, OAuth2/JWT with a refresh
cookie, 50,000 concurrent users, 99.9% availability, Kubernetes) and from the
page specifications in `docs/ui/`.

Inputs fixed before the decision: the team works in JavaScript/TypeScript and
the React ecosystem is kept, so the language is TypeScript and the choice is a
React meta-framework; SSR/SSG is required for the planned public pages; the
runtime is unconstrained; no mobile applications are planned; a full rewrite is
acceptable.

## Decision

- **Language:** TypeScript.
- **UI library:** React.
- **Meta-framework:** Next.js with the App Router (RSC + SSR/SSG/ISR).

Next.js is the stack for every Frontend page; the architecture on top of it
is defined in [ADR-019](adr-019-frontend-architecture.md).

## Why this decision

- It satisfies every must-have: server rendering for public pages, interactive
  app pages, i18n routing, image and font optimisation, and Core Web Vitals.
- It has the highest adoption in the ecosystem: 80% usage among respondents of
  the State of React 2025 survey, and about 1 billion npm downloads between May
  2025 and May 2026.
- It is mature: regular releases, LTS backports and the largest ecosystem of
  integrations and ready components.
- Migration from the stack documented so far (Next.js 14) is incremental — an
  upgrade to the current Next.js release — unlike a switch to another meta-framework.

## Alternatives

- **React Router v7 (framework mode)** — close runner-up: the cleanest
  route-based data model, strong forms and mutations, no React Server
  Components, backed by Shopify. Rejected as the primary stack because its
  ecosystem and ready integrations are smaller and migration from Next.js is a
  rewrite; it remains the recorded fallback if Next.js/RSC costs grow.
- **Astro 6** — rejected as the primary stack: best Core Web Vitals for content
  pages, but the authenticated app pages, dashboard statistics and maintenance
  tables are island-based and awkward.
- **TanStack Start** — rejected: rising, but the youngest option with fewer
  production references and less ecosystem support.
- **Vite + React SPA** — rejected: no server rendering, so the planned public
  pages could not be indexed.
- **Non-JavaScript stacks** (C#/Blazor, Dart, Kotlin, Rust) — outside the
  chosen React/TypeScript boundary.
- **Gatsby, Waku, RedwoodJS, Remix v2** — rejected: declining, experimental or
  in maintenance mode.

## Consequences

- Every Frontend page is built on Next.js App Router; the rendering, state
  and data-fetching rules follow [ADR-019](adr-019-frontend-architecture.md).
- Public pages are server-rendered (SSR/SSG/ISR); authenticated app pages fetch
  their data on the client.
- Concrete versions and dependencies live in the Frontend code; these documents
  record the stack above the version level.
- Accepted risks: React Server Components add complexity and have a security
  history (CVE-2025-55182), and Next.js is closely tied to Vercel; both are
  mitigated by using server rendering only where it is needed and by keeping
  React Router v7 as the fallback.
- Concrete versions are pinned in
  [`docs/architecture-overview.md` §1](../architecture-overview.md); the C4
  diagrams reference that section instead of repeating versions.

## Related artifacts

- `docs/adr/adr-019-frontend-architecture.md`.
- `docs/ui/pages.md`, `docs/ui/vacancies-market.md`, `docs/ui/flows.md`.
- `docs/technical-requirements.md` (1.5 Accessibility and localisation, 2.1
  Capacity).
- `docs/c4/containers.puml`, `docs/c4/components-frontend.puml`.
- `docs/architecture-overview.md` §1 (services and stacks).
