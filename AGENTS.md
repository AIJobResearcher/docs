# AIJobResearcher docs — Agent Instructions

## 1. Project

Docs + deployment repository; Markdown/YAML content only, no application code
or test suite.

1. `docs/` — content: pages, ADR, domain, api, event-storming,
   AsyncAPI, c4, loadtests
2. `deploy/` — Docker Compose helpers
3. `.github/workflows/ci.yml` — lint + link checks

## 2. Quality

1. Markdown follows `.ai-agent/standards/md-files-standards.md`;
   other formats mirror the edited file's style.
2. When renaming/moving/deleting a `docs/` file or heading, grep for
   references to it and update them.
3. Load the standard that matches the file kind: Markdown/agent files →
   `.ai-agent/standards/md-files-standards.md`; `docs/` content →
   `docs-files-standards.md`.
4. Patch only the affected section of a file; never rewrite or reformat a
   whole document just to make an edit.

## 3. Token Efficiency

1. Ambiguous scope or design decision: ask at most one round of
   questions; if none arrives, proceed on the most plausible default and
   mark choices "ASSUMPTION".
2. Report as a single short line — "Done — `<files>`" or "Done —
   `<file>`: <2-3 words>" — plus diff hunks only. No explanations,
   rationale, or step summaries unless asked.
3. Produce nothing unrequested: no tests, scenarios, diagrams, extra
   docs, or code.
4. Before editing, restate the task in one line and name the affected
   files (include order for multi-file tasks). Confirm scope only if
   ambiguous, then finish without interim reports.
5. Read and reference selectively: grep first, read only matching
   lines/ranges, never re-read content already summarized this
   session, and cite files by path + line range — not as content
   dumps.
6. Cap shell output to the model: pipe to `head`/`tail`/`grep`, show
   only the relevant lines or the error tail, never the full dump.
7. Reuse known values; avoid repeating identical operations in one
   session.
8. Keep AI temp artifacts (plans, lists, research) under
   `.ai-agent/agent.data`, each under 40 lines.
9. After ~20 messages or when context grows large, suggest a fresh
   session.
10. Task intake: silently check the request for a clear verb, a target
    `@file#L..L`, an expected result, and constraints. Ask — in one block,
    one round — only the gaps that are missing and material; otherwise
    apply the standing defaults in this file (output format, gates,
    boundaries) and mark choices ASSUMPTION.

## 4. Definition of done

1. Fully deliver the requested scope; interrupt only when genuinely
   blocked or scope is ambiguous (§3.1), and then state the single missing
   input that would unblock.

## 5. Limitations

1. Scope: this repo only.
2. Git (stage/commit/push) is handled by the user.
3. Ask first: adding dependencies, changing project configs
   (`.markdownlint.json`, `.yamllint.yaml`, `lychee.toml`, `Makefile`,
   `.github/workflows/`), restructuring, or deleting/overwriting
   files.
4. Never run analyzers/tests/dependency updates on your own initiative
   (markdownlint, yamllint, Lychee, `make test*`, npm install). Run
   them ONLY on an explicit "run" request or "fix and verify". A
   pasted error list alone means: fix exactly what is reported and
   STOP — no tool runs, no extra analyzers, no widened scope. Do not
   self-verify edits by running gates. On an explicit run request,
   scope to the changed files only and re-report briefly.
5. Change only what the task requires — no speculative rewrites or
   reformats of unrelated files or sections.
6. Never put secrets, credentials, API keys, or real tokens into files or
   output; refer to `.env` by variable name only.
