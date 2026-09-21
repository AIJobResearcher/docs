# Token Economy Rules

Apply with the project `AGENTS.md` and `md-files-standards.md` (shared
rules); this file adds token-economy rules only and loads before any task
that reads, searches, or edits the repository. General behaviour rules stay
in `AGENTS.md`; here are their token consequences. Cost driver: every model
call replays the whole conversation, so spend scales with calls × context
size — fewer calls and a smaller context beat any wording change. Measured:
one 37-turn session with 292 tool calls cost 48.5M input tokens, about
160K per call.

## 1. Reading

- **1.1** Search first, then `read` with offset/limit; never read a whole
  file or log in one call.
- **1.2** Cap command and log output with `head`/`tail`/`grep`; a full dump
  is paid again on every later call.
- **1.3** Name the working set — the files, or the one directory — before
  any exploration; never tour the tree.

## 2. Editing

- **2.1** Read a file once and edit it from that read; group all edits of
  one file into a single step.
- **2.2** If an edit is rejected because the file changed (parallel IDE
  edits), re-read that file once and retry; never rescan the repository.
- **2.3** On a failed tool call, retry it once with a simpler input; if it
  fails again, switch to the documented fallback for that tool (shell `grep`
  for content search) and name the substitution in the closing line. With no
  documented fallback, stop retrying and report the failure in that line.

## 3. Batching

- **3.1** Issue independent calls in one turn — several reads, several
  greps, or read plus lint; each extra round-trip re-sends the context.
- **3.2** Never re-verify what an earlier call already proved.

## 4. Context

- **4.1** Tool output stays in history forever: never paste file contents
  or raw logs back into the conversation.
- **4.2** Write long results to `.ai-agent/agent.data/artifacts/` and
  reference them by path and line range.

## 5. Deliberation

- **5.1** At most five short bullets before acting.
- **5.2** Never restate the task, the standards, or code just read.
- **5.3** Never re-open a decision settled in this session or in
  `.ai-agent/DECISIONS.md`.
- **5.4** Reasoning was 55–73% of output tokens in the reviewed sessions;
  trim it before any other output.

## 6. Prompt cache

- **6.1** Keep the always-loaded prefix (`AGENTS.md`, standards)
  byte-stable during a task; change it between sessions.
- **6.2** One changed character before the cache breakpoint invalidates
  everything after it; a cache read costs ≈ 0.1× base input, a write
  1.25–2×.

## 7. Sessions

- **7.1** One feature per session; on an unrelated task reset or compact
  instead of continuing.
- **7.2** At 20 messages or 300 tool calls, write a handoff note — state,
  files, next step, open questions — to the artifact directory (4.2) and
  continue in a fresh session.

## 8. Verification

- **8.1** Verify with the cheapest check the repo supports (`php -l` for
  PHP, `bash -n` for shell, a parse check for YAML, none for prose) and
  prefer one narrow runtime call through `docker exec` (`curl`, `psql`) to
  analyzers and full test gates, which run only on request (`AGENTS.md` 5.4).
- **8.2** A failed call costs the turn twice — pre-flight the cheap failure
  classes: file permissions, container user, empty database, missing binding,
  and arguments the tool rejects (search patterns, paths).

## 9. Routing

- **9.1** Run mechanical work — renames, formatting, bulk seeders, log
  triage — on a cheaper model or as a subagent task.
- **9.2** Keep the strong model for design and review; never spend it on
  syntax-level edits.

## 10. Delegation

- **10.1** Send broad read-only exploration and documentation lookups to a
  subagent: its tool output never enters the main context, only its
  conclusions do (the reviewed window used 0 subagents).

## 11. Web search

- **11.1** Measured: page fetching, not the search, is the cost — 12
  searches, all inside the session holding 55% of the window's input
  tokens, where `web_fetch` was the second-most-used tool.
- **11.2** Search the repo first: code, docs, and the `vendor/` source of
  the pinned framework version answer Laravel/PHP questions exactly and
  cheaply; the web is the last resort.
- **11.3** Send one `web_search` with up to four queries, never repeated
  single searches; refine only when the first result set is empty.
- **11.4** Cap `web_fetch` at two pages per question, and only pages that
  will change the decision; documentation and paper pages are huge —
  extract the needed lines and stop.
- **11.5** Save the answer, source URL, and date in the artifact directory
  (4.2); a search that ends without a recorded answer is wasted budget.
- **11.6** After a session that used the web, re-check its cost: reusable
  knowledge belongs in an artifact or a standard, never in another search
  tomorrow.

## 12. Reporting

- **12.1** Report in one line — "Done — `<files>`" — plus diff hunks, the
  check that was run, and the acceptance criterion when it was assumed;
  prose reports are re-sent on every later call.
- **12.2** Keep saved artifacts under 40 lines.
- **12.3** No rationale unless asked.

## 13. Measurement

- **13.1** Record per task: tokens, cache hit rate, tool calls, failures.
- **13.2** Re-run session-insights monthly; drop any rule that does not
  move these numbers.

## 14. Questions

- **14.1** Ask at most once, in one block, only for material missing inputs;
  every round-trip re-sends the context, so drip-fed questions cost the task
  twice (3.1).
- **14.2** Inputs that count as material: goal, files or layer, acceptance
  criteria, temporary versus permanent, constraints, and the destructive
  semantics of an operation when two readings are plausible (overwrite
  versus delete).
- **14.3** Without them, apply the repo defaults and mark ASSUMPTION instead
  of asking.
