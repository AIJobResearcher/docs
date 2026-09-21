# Agent instruction optimization review

Status: reusable prompt · Date: 2026-09-21 · Owner: engineering

1. Mission

- 1.1 Produce a measured review of the agent instruction files — root
  `AGENTS.md`, `.ai-agent/DECISIONS.md`, `.ai-agent/standards/*.md` — from
  session analytics, and write it to
  `.ai-agent/user.data/agents-optimization-<YYYY-MM-DD>.md`.
- 1.2 Propose only. Never edit the reviewed files during this run; every
  proposal ships as a paste-ready before/after block the user applies.
- 1.3 Judge a rule by what it costs and what it prevents: every line of these
  files is replayed on every model call, so fewer and sharper rules beat more
  rules.

2. Sources, in priority order

- 2.1 Primary — session insights. Use the newest run under
  `$DSH_HOME/insights/runs/*/` and read `report.json` (never the HTML), plus
  `manifest.json`, `base-report.json` and `semantic-report.json`.

```sh
ls -dt "${DSH_HOME:-$HOME/.dsh}"/insights/runs/*/ | head -1
```

- 2.1.1 No run, or a run covering fewer than three sessions: stop and ask the
  user for `/session-insights --days 30 --locale en`. Never start a run.
- 2.2 Secondary — usage and cost: `$DSH_HOME/usage-unified/index-v1.json` for
  machine-wide tokens, the cache split and per-model buckets, and
  `pricing.json` when present for real cost. Cost per model shows whether a
  rule change pays off.
- 2.3 Secondary — context composition: the `dsh-context` panel reports what the
  window is made of (system prompt, tool schemas, injected instructions,
  messages). Use the numbers the user supplies from the Context tab; if they
  were not supplied, mark the dimension unavailable rather than guessing.
- 2.4 Secondary — repository history: `git log --since=<window start>
  --name-only`, `git status --short` and `git diff --stat` for rework hotspots
  and for whether finished work was committed.
- 2.5 Targets under review: `AGENTS.md`, `.ai-agent/DECISIONS.md`,
  `.ai-agent/standards/*.md`.
- 2.6 Optional, only when the user hands the output over: analyzer and test
  results (`phpstan`, `phpcs`, `psalm`, `junit.xml`, CI logs). Never run those
  tools: `AGENTS.md` 6 forbids it without an explicit request.

3. Method

- 3.1 Fix the sample first: run id, window, sessions, turns, tool calls, tokens
  in and out, reasoning share, cache-hit rate, cost.
- 3.2 Extract frictions: tool failures, unchanged retries, aborted turns,
  correction messages, non-zero diagnostics, and every `frictions` entry of the
  semantic facets with its evidence ids. Record strengths too — a rule that
  already works must not be rewritten.
- 3.3 Attribute each friction to an instruction or to a missing one, in one of
  four classes: missing rule, ignored rule, rule costing more than it saves,
  rule duplicated in another file.
- 3.4 Accept a proposal only with all three: a measured number from 3.1–3.2, a
  citation `path#Lx-Ly` of the text being changed, and the exact replacement.
  Drop anything that cannot carry all three.
- 3.5 Check every proposal against `md-files-standards.md` (3.1.x governs where
  global rules may live) and against `DECISIONS.md`. A proposal that contradicts
  a settled decision is labelled as such and left for the user to rule on.
- 3.6 Prefer deletions, merges and shorter wording over new rules.
- 3.7 Never propose a rule that asks the agent to run analyzers, tests,
  migrations or dependency updates on its own initiative.

4. Output contract

- 4.1 Exactly one file, in English, compliant with `md-files-standards.md`:
  `.ai-agent/user.data/agents-optimization-<YYYY-MM-DD>.md`.
- 4.2 Sections in this order:
  - 4.2.1 Scope and sources: run id, window, sample size, sources read, sources
    unavailable and why.
  - 4.2.2 Findings: numbered, each with the metric, the observed behaviour and
    the evidence id.
  - 4.2.3 Proposals: grouped per target file; each carries target
    `path#Lx-Ly`, problem, before/after block, expected effect, risk, priority
    (P0 now, P1 next review, P2 opportunistic) and evidence ids.
  - 4.2.4 Rejected ideas with the reason — no evidence, already covered,
    contradicts a decision.
  - 4.2.5 Open questions, at most three, each with a recommended default.
- 4.3 Keep the file near 120 lines unless the findings genuinely need more.

5. Cost discipline

- 5.1 Read the insight report once and work from notes; the report already
  folded the raw session logs, so never re-read those logs.
- 5.2 `grep` before `read`, and read line ranges rather than whole files.
- 5.3 The output is proposals, not a digest: never summarize the standards or
  the report back to the user.

6. Stop conditions

- 6.1 Fewer than five measurable frictions: report that the sample is too thin
  for structural change and list what to measure next.
- 6.2 Insights and repository history disagree about what was finished (for
  example a report claiming completion while `git log` shows no commit): report
  the contradiction in one line instead of choosing a side.
