# MD files Standards

Apply to every Markdown file written or edited in this repository.

## 1. Formatting requirements

1. Headings: ATX hash style, one space after the hashes; no setext
   underlines. ✅ `## Overview`
2. Unordered lists: dashes only (`- item`), never `*` or `+`.
3. No trailing spaces and no two-space hard breaks — separate blocks with
   blank lines.
4. Prose and headings wrap at 80 characters; code blocks and table rows may
   be longer.
5. No duplicate headings among siblings — one occurrence per parent; the same
   heading under different parents is fine.
6. Horizontal rule: `---`, never `***` or `___`.
7. Names capitalized exactly: AIJobResearcher, GitHub, GitHub Actions,
   Docker, Docker Compose, YAML, Markdown, OpenAPI, AsyncAPI, Gherkin,
   Cucumber, Lychee, markdownlint (text only, code excluded).
8. No raw HTML or bare angle brackets (`<br>`, `list<string>`) — wrap them in
   inline code; never `<br>` inside tables.
9. Code blocks: fenced with three backticks, blank line before and after;
   indented blocks are forbidden; add a language label (json, sql, text)
   after the opening fence.
10. Fences: backticks, not tildes.
11. Emphasis: asterisks (`*i*`, `**b**`), not underscores.

## 2. Document structure and completeness

1. Number headings hierarchically (`1.`, `1.1`, `1.1.1`); no skipped or
   repeated numbers; depth of three levels or fewer.
2. Standalone documents open with 2–4 sentences: purpose, audience, scope.
3. Cross-reference sections by number (`see 1.1`), one style per file.
4. Link, do not duplicate — one source of truth per fact.
5. First occurrence of every domain term links to `docs/glossary.md`; never
   redefine terms inline.
6. Headings state exactly what their section contains and match sibling
   form; no empty headings.
7. Normative or living documents carry a status line or revision table
   (status, date, author, note); ADR files follow their template.
8. Ship nothing unfinished: no `TODO`, `TBD`, placeholder ellipses, or empty
   sections.

## 3. Before you finish

1. Structure: hierarchical numbered headings, no empty headings, purpose
   block present (§2).
2. Type: ADR and requirements files include their mandatory elements (§4).
3. References: numeric cross-links used, relative links resolve, first
   glossary term linked.
4. No duplicated facts — link what already exists.
5. Clean text: no `TODO`/`TBD`, trailing spaces, raw HTML, or prose over 80
   characters (§1).

## 4. Document-type requirements

Mandatory type-specific elements on top of sections 1 and 2.

### 4.1 ADR

In `docs/adr/`, one file per decision.

1. File: `adr-NNN-<slug>.md`; NNN is the next free zero-padded number, never
   reused or renumbered.
2. Title: `# ADR-NNN: <Decision summary>`.
3. Sections in fixed order: Context, Decision, Why this decision,
   Alternatives, Consequences, Related artifacts.
4. Decision records concrete choices; Alternatives lists rejected options
   with reasons. Link other ADRs instead of duplicating them.
5. Optional lifecycle header after the title: `**Status:** proposed |
   accepted | superseded`, `**Date:** YYYY-MM-DD`; a superseded ADR names its
   replacement.

### 4.2 Technical requirements

Pattern file: `docs/technical-requirements.md`.

1. Metadata block after the title: `**Version:**`, `**Target load:**`,
   `**Application version:**`.
2. After a `---` divider, a `> **Related documentation:**` blockquote linking
   glossary, overview, and related documents.
3. Numbered sections (`1.`, `1.1`); quantified requirements (SLO, latency,
   capacity) are tables with named columns and explicit units, not prose.

### 4.3 Bounded-context pages

In `docs/domain/bounded-contexts/`, one page per context.

1. Title: `# Bounded Context: <Name> (<Service> Service)`.
2. Related-documentation blockquote right after the title (glossary,
   architecture overview, domain model, repository README).
3. Core section order: Responsibility, Key NFRs, Business processes, User
   stories, Business invariants, Domain events, Aggregates and entities,
   Interaction with other contexts, Implementation.
4. Context-specific extras may be added where they fit (e.g. integration
   contract).
5. Under "Aggregates and entities", each aggregate/entity is an `###`
   heading; root aggregates are marked `(root)`.

### 4.4 Event-storming pages

In `docs/event-storming/`, one page per business process stream.

1. Title: `# Event Storming: <Domain>`.
2. Sections: Commands (triggers), Domain events, Aggregates, Business rules
   (invariants); "Integration messages" only for events crossing contexts.
3. Entries: `**<Name>** – one-line description`; reuse the bounded-context
   names (same Ubiquitous Language).

### 4.5 API specifications

One OpenAPI file per service, `docs/api/<service>/openapi.yaml`. These are
YAML — Markdown rules do not apply inside them: formatting follows
`.yamllint.yaml`, correctness the OpenAPI specification. Reference the file
from the bounded-context page; the service name in the path equals the
bounded context name.
