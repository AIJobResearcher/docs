# MD files Standards

## 1. Formatting requirements

- **1.1** Headings: ATX hash style, one space after the hashes; no setext
  underlines. ✅ `## Overview`
- **1.2** Unordered lists: dashes only (`- item`), never `*` or `+`.
- **1.3** No trailing spaces and no two-space hard breaks — separate blocks
  with blank lines.
- **1.4** Prose and headings wrap at 80 characters; code blocks and table
  rows may be longer.
- **1.5** No duplicate headings among siblings — one per parent; the same
  heading under different parents is fine.
- **1.6** Horizontal rule: `---`, never `***` or `___`.
- **1.7** Names capitalized exactly: AIJobResearcher, GitHub, GitHub
  Actions, Docker, Docker Compose, YAML, Markdown, OpenAPI, AsyncAPI,
  Gherkin, Cucumber, Lychee, markdownlint (text only, code excluded).
- **1.8** No raw HTML or bare angle brackets (`<br>`, `list<string>`) —
  wrap in inline code; never `<br>` inside tables.
- **1.9** Code blocks: fenced with backticks (not tildes), blank line
  before and after; indented blocks forbidden; add a language label (json,
  sql, text) after the opening fence.
- **1.10** Emphasis: asterisks (`*i*`, `**b**`), not underscores.

## 2. Document structure

- **2.1** Number every referenceable unit in one hierarchy: headings `1.`,
  subheadings `1.1`; each content item — every bullet, list item, and thematic
  paragraph under a numbered section — inherits the section number plus an
  ordinal as a bold dash-bullet label (`1.1`, `1.2`, `2.3`). No item is left
  without a number, no skipped or repeated numbers; depth of three levels or
  fewer.
- **2.2** Standalone documents open with 2–4 sentences: purpose, audience,
  scope.
- **2.3** Cross-reference sections by number (`see 1.1`), one style per
  file.
- **2.4** Reference, do not duplicate or paste: link by relative path and
  line range (`path#L10-L20`); keep one source of truth per fact.
- **2.5** First occurrence of every domain term links to `docs/glossary.md`;
  never redefine terms inline.
- **2.6** Headings state exactly what their section contains and match
  sibling form; no empty headings.
- **2.7** Normative or living documents carry a status line or revision
  table (status, date, author, note).
- **2.8** Keep the items of a document mutually consistent and
  non-overlapping — no rule repeats or contradicts another; merge overlaps
  into one terse rule.

## 3. Agent-system files

### 3.1 AGENTS.md

- **3.1.1** One top-level heading; numbered section headings (see section 2
  of this file).
- **3.1.2** Loaded into every session — keep only pointers and stable
  facts; every line must earn its place. Move detail and drifting content to
  standards files or live configs; link, never duplicate.
- **3.1.3** Global behaviour rules (reporting, file access, no auto runs,
  security) belong to the root `AGENTS.md`; never copy them into standards.
- **3.1.4** Keep one canonical section order — scope, quality, behaviour,
  done, limits — for instant navigation.
- **3.1.5** Phrase rules as an action plus scope plus the rare exception,
  never as a principle or "be …" filler.
- **3.1.6** Never store secrets, credentials, or absolute personal paths.
- **3.1.7** Update when a language or service is added, or when a repeated
  agent mistake reveals a missing rule; it is a living file.
- **3.1.8** Keep the same section titles and numbers across every project's
  `AGENTS.md` so references stay stable.

### 3.2 Standards files

- **3.2.1** Platform-document rules (2.2, 2.6, 2.7) do not apply; headings
  are 1–3 words that label, never describe.
- **3.2.2** Maximally dense — one directive per line, every word earned; no
  filler, connectors, or explanation.
- **3.2.3** The standards set: `md-files-standards.md` (general Markdown),
  `docs-files-standards.md` (docs), and the language standards
  `php-standards.md`, `laravel-standards.md`, `python-standards.md`,
  `react-standards.md`.
- **3.2.4** On a conflict the more specific file wins — a language or docs
  standard overrides the general one; otherwise surface the contradiction
  to the user instead of guessing.
- **3.2.5** Standards files load on demand by task type; each is
  self-contained yet short and references common rules instead of repeating
  them.
