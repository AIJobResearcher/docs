# Documentation Standards

## 1. All documentation files

- **1.1** One file per decision/page/context.
- **1.2** English only.
- **1.3** After the title, add a metadata header as `**…:**` lines, one per
  line: required `**Status:** proposed | accepted | superseded` and
  `**Date:** YYYY-MM-DD`, plus type-specific fields (`**Version:**`,
  `**Target load:**` etc., see section 2). A superseded file names its
  replacement.
- **1.4** Pages that relate to other artifacts open content with
  `> **Related documentation:**` linking the Glossary and the closest related
  documents; relative links, continuation lines separated by `|`. Omit the
  blockquote in the glossary and the docs home, which are link targets.
- **1.5** Documentation structure: overview pages and standalone docs in
  `docs/` root, ADRs in `docs/adr/`, domain pages in `docs/domain/`, event
  streams in `docs/event-storming/`, UI page specs in `docs/ui/`.

## 2. ADR

In `docs/adr/`, one file per decision.

- **2.1** File: `adr-NNN-<slug>.md`; NNN is the next free zero-padded number,
  never reused or renumbered.
- **2.2** Title: `# ADR-NNN: <Decision summary>`.
- **2.3** Sections in fixed order: Context, Decision, Why this decision,
  Alternatives, Consequences, Related artifacts.
- **2.4** Decision records concrete choices; Alternatives lists rejected
  options with reasons. Link other ADRs instead of duplicating them.
- **2.5** ADRs from 019 on carry `**Status:**` and `**Date:**` per 1.3; older
  records are backfilled when they are next touched.

## 3. UI page spec

In `docs/ui/`: `pages.md` indexes the pages, `flows.md` holds the user flows,
one file per page.

- **3.1** File `<page-slug>.md`, title `# UI Page Specification: <Page>`.
- **3.2** Sections in fixed order: Scope, Page, Blocks, API Operations, States,
  Behaviour, Edge Cases, Related Documents.
- **3.3** `Page` fixes route, access, purpose, menu, layout, header,
  accessibility and localisation; one page has one route.
- **3.4** `Blocks` names the model fields each block renders.
- **3.5** `API Operations` maps blocks to endpoints; keep schemas in OpenAPI,
  never restated here.
- **3.6** `States` is one Mermaid `stateDiagram-v2`; `flows.md` references it
  instead of repeating it.
- **3.7** Register every page and its route in `pages.md`.

## 4. Before you finish

Final self-check before you mark a documentation task done:

- **4.1** After a review changes a file, update its metadata header: set
  `**Date:**` to today and bump `**Version:**` by one tenth (e.g. `1.0` →
  `1.1`).
