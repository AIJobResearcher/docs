# AIJobResearcher docs — Agent Instructions

## 1. Project

Docs + deployment repository; Markdown/YAML content only, no application code
or test suite.

1. `docs/` — pages, ADR, domain, api, event-storming, AsyncAPI, c4, loadtests, ui
2. `deploy/` — Docker Compose helpers
3. `.github/workflows/ci.yml` — lint + link checks

## 2. Quality

1. Before editing a file, load and strictly obey its standard, and read
   `.ai-agent/DECISIONS.md` (it outranks every standard): Markdown/agent
   files → `.ai-agent/standards/md-files-standards.md`; any `docs/` content
   → `docs-files-standards.md`; other formats mirror the edited file's
   style.
2. Renaming/moving/deleting a `docs/` file or heading: grep for references and
   update them.
3. Change and produce only what the task requires: patch only the affected
   section; no speculative rewrites/reformats of a whole document, no extra
   artifacts.

## 3. Token Economy

1. `.ai-agent/standards/token-economy-rules.md` is mandatory: read it once
   before the first search, read, or edit of every task and follow it as
   written.
2. It is the only source of truth for reading, editing, batching, context,
   deliberation, asking, prompt cache, sessions, verification, routing,
   delegation, web search, reporting, and measurement: never restate, weaken,
   or work around its rules — a rule breached on a small task is still
   breached.

## 4. Definition of done

1. Fully deliver the requested scope; interrupt only when genuinely blocked or
   scope is ambiguous, stating the single missing input that would unblock.

## 5. Limitations

1. Scope: this repo only.
2. Git (stage/commit/push) is handled by the user.
3. Ask first before adding dependencies, changing project configs
   (`.markdownlint.json`, `.yamllint.yaml`, `lychee.toml`, `Makefile`,
   `.github/workflows/`), restructuring, or deleting/overwriting files.
4. Never run analyzers, tests, or installs on your own (markdownlint, yamllint,
   Lychee, `make test*`, npm install); run them only on an explicit "run" /
   "fix and verify" request, scoped to the changed files, then re-report
   briefly. A pasted error list means: fix exactly that and stop — no tool
   runs, no extra checks.
5. Never put secrets, credentials, or real tokens in files or output; reference
   `.env` variables by name only.
