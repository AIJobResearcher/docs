# React Code Standards

React 19.2, Next.js 16.3 App Router, TypeScript 7 (ADR-020); strict tsconfig,
typescript-eslint, React Compiler.

## 1. Types

- **1.1** No `any`; validate external data at the boundary; derive types from
  the OpenAPI client or validator, never duplicate shapes.
- **1.2** Type props and state explicitly; discriminated unions over optional
  flags; no `!` or `as` on untrusted data; never mutate props or state.

## 2. Components

- **2.1** Function components and hooks only; one per file, `PascalCase`, named
  exports (default only for routes); no nested component declarations.
- **2.2** Pure render: no side effects, I/O, ref access or non-deterministic
  values.
- **2.3** No business logic or transport in components; stable ids as `key`;
  handle every promise; avoid `dangerouslySetInnerHTML`.

## 3. State and Effects

- **3.1** Minimal colocated state, one source of truth; derive instead of
  storing; reset by `key`.
- **3.2** Server state in TanStack Query; never copy it into local state.
- **3.3** Effects only synchronize external systems; complete deps, cleanup,
  abort fetches; StrictMode-safe.
- **3.4** `useReducer` for multi-field transitions; `useTransition`/
  `useDeferredValue` for non-urgent updates; `useSyncExternalStore` for
  external stores.

## 4. Hooks

- **4.1** Top level only; custom hooks are `use*`, one concern each.
- **4.2** Memoize only measured hotspots the React Compiler misses.

## 5. Data and Next.js

- **5.1** Public pages server-render (SSR/SSG/ISR); app pages client-fetch via
  TanStack Query (ADR-019).
- **5.2** All calls go through the generated OpenAPI client; auth and
  `Correlation-ID` live there; no ad-hoc `fetch` or `axios`.
- **5.3** One cache key per resource and params; precise invalidation; parallel
  requests; model loading, empty, error and unauthorized; append-only infinite
  queries; no per-user data in shared caches.
- **5.4** Server Components by default; `'use client'` only at interactive
  leaves; `server-only` for server modules; only `NEXT_PUBLIC_*` reaches the
  client.
- **5.5** Stream with Suspense and `loading.tsx`; `error.tsx`/`not-found.tsx`;
  mutate through Server Actions or route handlers with server-side validation
  and explicit revalidation; cache explicitly; Metadata API for public pages.

## 6. Contracts and Errors

- **6.1** Specs are the source of truth; regenerate and commit the client on
  change; no contract change without authorization; two backends only, no BFF.
- **6.2** Typed errors, no empty `catch`; one error boundary per route or
  feature with retry.
- **6.3** Map codes: `401` refresh once then error, `429` retry-after, `5xx` or
  network retry; user copy at the boundary; log with the correlation id, never
  secrets or PII.

## 7. Security

- **7.1** Access token in memory, refresh token in an httpOnly cookie; never
  `localStorage`.
- **7.2** Secrets server-side only; `server-only` and taint APIs for sensitive
  objects; CSP and security headers.
- **7.3** Encode output, validate server-side, authorize at the data layer; pin
  dependencies.

## 8. Quality

- **8.1** Budgets: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1, TTFB ≤ 500 ms;
  `next/image` with `sizes`, `next/font`, `next/dynamic`; virtualize long
  lists; profile before optimizing.
- **8.2** WCAG 2.1 AA: keyboard, visible focus, contrast 4.5:1, labels/ARIA,
  `alt`; semantic HTML; trap focus; live regions; reduced motion.
- **8.3** Strings as i18n keys; `Intl` formatting; no fixed-width text
  containers.
- **8.4** Test behavior by role and label in the existing framework; mock the
  network, not modules; a regression test per fix.
- **8.5** Feature-sliced `app/` → `features/` → `entities/` → `shared/`,
  downward imports only; `PascalCase`/`camelCase`/`UPPER_SNAKE_CASE`/
  `kebab-case`; zero-warning lint and type-check in CI.
