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

## 3. Before you finish

Final self-check before you mark a documentation task done:

- **3.1** After a review changes a file, update its metadata header: set
  `**Date:**` to today and bump `**Version:**` by one tenth (e.g. `1.0` →
  `1.1`).
