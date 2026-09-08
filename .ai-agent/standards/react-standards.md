# React Code Standards

Apply with the project `AGENTS.md` and `md-files-standards.md` (shared
rules); this file adds React/Next.js (TypeScript) rules. Binding: strict
`tsconfig.json` and the repository's typescript-eslint configuration.

## 1. Types

- **1.1** Never use `any`; isolate external boundaries behind typed adapters and
  never bypass types with unchecked casts unless adjacent runtime validation
  exists.
- **1.2** Type props and state explicitly and derive them from one source of
  truth.

## 2. Components

- **2.1** Write functional components with hooks only (no class components);
  obey the Rules of Hooks.
- **2.2** Keep components free of business logic — server/client state,
  validation, and transport live in typed hooks, services, or route handlers.
- **2.3** Handle every promise; no floating or unhandled promise rejections.
- **2.4** Sanitize all rendered output (XSS) and validate untrusted server or
  API data at the boundary before use.

## 3. Next.js

- **3.1** Respect server/client boundaries: DB access, secrets, and business
  calls run server-side only and must not leak into serialized client props.

## 4. Contracts

- **4.1** Treat the OpenAPI/AsyncAPI specs as the source of truth for client
  types and payloads; never hardcode contract shapes.
- **4.2** Never change a public HTTP or event contract without authorization;
  update the spec, the client, and all consumers in the same change.

## 5. Naming

- **5.1** Components and types: `PascalCase`; variables, functions, hooks:
  `camelCase`; constants: `UPPER_SNAKE_CASE`.
- **5.2** One component per file, file named after the component.

## 6. Error handling

- **6.1** Throw and catch typed errors; never swallow in an empty `catch`.
- **6.2** Surface user-facing errors at the boundary; keep the rest structured.

## 7. Tests

- **7.1** If tests are requested, follow existing `*.test.ts(x)` patterns —
  introduce no new framework.
