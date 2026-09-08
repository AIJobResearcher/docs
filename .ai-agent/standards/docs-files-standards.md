# Documentation Standards

## 1. ADR

In `docs/adr/`, one file per decision.

- **1.1** File: `adr-NNN-<slug>.md`; NNN is the next free zero-padded number,
  never reused or renumbered.
- **1.2** Title: `# ADR-NNN: <Decision summary>`.
- **1.3** Sections in fixed order: Context, Decision, Why this decision,
  Alternatives, Consequences, Related artifacts.
- **1.4** Decision records concrete choices; Alternatives lists rejected options
  with reasons. Link other ADRs instead of duplicating them.
- **1.5** Optional lifecycle header after the title: `**Status:** proposed |
  accepted | superseded`, `**Date:** YYYY-MM-DD`; a superseded ADR names its
  replacement.

## 2. Technical requirements

Pattern file: `docs/technical-requirements.md`.

- **2.1** Metadata block after the title: `**Version:**`, `**Target load:**`,
  `**Application version:**`.
- **2.2** After a `---` divider, a `> **Related documentation:**` blockquote
  linking glossary, overview, and related documents.
- **2.3** Numbered sections (`1.`, `1.1`); quantified requirements (SLO,
  latency, capacity) are tables with named columns and explicit units, not
  prose.

## 3. Bounded-context pages

In `docs/domain/bounded-contexts/`, one page per context.

- **3.1** Title: `# Bounded Context: <Name> (<Service> Service)`.
- **3.2** Related-documentation blockquote right after the title (glossary,
  architecture overview, domain model, repository README).
- **3.3** Core section order: Responsibility, Key NFRs, Business processes, User
  stories, Business invariants, Domain events, Aggregates and entities,
  Interaction with other contexts, Implementation.
- **3.4** Context-specific extras may be added where they fit (e.g. integration
  contract).
- **3.5** Under "Aggregates and entities", each aggregate/entity is an `###`
  heading; root aggregates are marked `(root)`.

## 4. Event-storming pages

In `docs/event-storming/`, one page per business process stream.

- **4.1** Title: `# Event Storming: <Domain>`.
- **4.2** Sections: Commands (triggers), Domain events, Aggregates, Business
  rules (invariants); "Integration messages" only for events crossing contexts.
- **4.3** Entries: `**<Name>** – one-line description`; reuse the
  bounded-context names (same Ubiquitous Language).

## 5. API specifications

One OpenAPI file per service, `docs/api/<service>/openapi.yaml`. These are
YAML — Markdown rules do not apply inside them: formatting follows
`.yamllint.yaml`, correctness the OpenAPI specification. Reference the file
from the bounded-context page; the service name in the path equals the
bounded context name.

- **5.1** Change OpenAPI or AsyncAPI only together with the code change it
  describes; never edit a spec separately.
- **5.2** A breaking contract change updates the spec, the client, and all
  consumers in the same change and is recorded in an ADR.
- **5.3** Check producer–consumer compatibility before altering a shared event
  schema; reuse event names from the event-storming pages (§4).

## 6. Before you finish

Final self-check before you mark a documentation task done:

- **6.1** Structure: hierarchical numbered headings, no empty headings, purpose
  block present (`md-files-standards.md`, section 2).
- **6.2** Type: the file follows the matching section of this document (ADR,
  requirements, bounded-context, event-storming, or API).
- **6.3** References: numeric cross-links used, relative links resolve, first
  glossary term linked.
- **6.4** No duplicated facts — link what already exists.
- **6.5** Clean text: no `TODO`/`TBD`, trailing spaces, raw HTML, or prose over
  80 characters (`md-files-standards.md`, section 1).
