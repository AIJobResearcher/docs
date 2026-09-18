# ADR-019: Frontend Architecture

**Status:** accepted
**Date:** 2026-09-18

## Context

The Frontend service (React 19.2, Next.js 16.3 App Router, TypeScript 7) renders
the user interface over the backend APIs. The page specifications in `docs/ui/`
define authenticated, highly interactive pages (vacancy list with tags and
infinite scroll, details, desired-jobs bar); public pages with SEO are planned.
No rendering, state, data-fetching or BFF decision was recorded, and
`docs/c4/components-frontend.puml` left the stack open (`Redux/Context`,
`Fetch/Axios`).

The OpenAPI specifications are the source of truth for payloads
(`.ai-agent/standards/react-standards.md` 4.1), and the page spec expects the
access token in memory with a refresh token in an httpOnly cookie
(`docs/ui/vacancies-market.md` 4.3).

## Decision

- **Rendering:** Next.js 16.3 App Router. Public pages are rendered on the server
  (SSR/SSG/ISR) for SEO and Core Web Vitals; authenticated app pages render the
  shell on the server and fetch their data on the client, because they are
  interactive and not indexed.
- **State:** server state lives in a caching data-fetching library
  (TanStack Query); local UI state lives in React hooks. No global Redux or
  Context store.
- **Data fetching:** one typed API client generated from the OpenAPI specs.
  The Frontend calls the backend APIs directly — Vacancies Market and
  ResearcherCrm — with no BFF.
- **Auth:** the access token is kept in memory and the refresh token in an
  httpOnly cookie; on `401` the client refreshes once, then shows the error
  state.
- **Localisation:** English UI now; user-facing strings are kept as keys.
- **Accessibility:** WCAG 2.1 AA for components (keyboard, focus, contrast,
  ARIA); see `docs/technical-requirements.md` 1.5.

## Why this decision

- Client-side data fetching fits the interactive app pages (infinite scroll,
  tag filters, in-memory state) and they need no SEO; public pages are
  server-rendered for indexing and Core Web Vitals.
- A generated typed client keeps frontend types in sync with OpenAPI and
  removes hand-written payloads.
- No BFF keeps the number of deployables low: the two backend APIs already
  expose what the pages need.
- One cache library for server state avoids a global store and its
  boilerplate.

## Alternatives

- **RSC/SSR data fetching for every page** — rejected: the app pages are
  authenticated and interactive; server rendering is used only where SEO and
  Core Web Vitals require it.
- **Global Redux/Context store** — rejected: there is no cross-page client
  state to share; server state belongs in the cache.
- **BFF at `docs/api/frontend/`** — rejected: an extra deployable without a
  clear need.
- **Hand-written `fetch`/`axios` clients** — rejected: they drift from the
  OpenAPI contracts.

## Consequences

- `docs/c4/components-frontend.puml` shows the App Router, UI components, the
  generated API client and the server-state cache; the `Redux/Context` and
  `Fetch/Axios` options are removed.
- Frontend types are regenerated from OpenAPI; a contract change updates the
  client in the same change.
- The rendering and state approach is fixed by this ADR; concrete library
  versions live in the Frontend code.
- UI components meet WCAG 2.1 AA; accessibility checks are part of component
  work.
- Public pages are server-rendered (SSR/SSG/ISR); app pages stay client-fetched.

## Related artifacts

- `docs/adr/adr-020-frontend-stack-selection.md` (stack choice this ADR builds on).
- `docs/ui/vacancies-market.md`, `docs/ui/pages.md`, `docs/ui/flows.md`.
- `docs/api/vacancies-market/openapi.yaml`, `docs/api/researcher-crm/openapi.yaml`.
- `docs/technical-requirements.md` (1.5 Accessibility and localisation).
- `docs/c4/components-frontend.puml`, `docs/c4/containers.puml`.
- `.ai-agent/standards/react-standards.md`.
