# Bounded Context: Learning Management (KnowledgeCenter Service)

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.3

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [Context Map](../../context-map.md) |
> [OpenAPI](../../api/knowledge-center/openapi.yaml) |
> [AsyncAPI](../../asyncapi/events.yaml) |
> [Technical Requirements](../../technical-requirements.md) |
> [README](../../README.md)
>
> **Related ADRs:** [ADR‑004: Using Go for the KnowledgeCenter
> Service](../../adr/adr-004-go-for-knowledge.md) |
> [ADR‑006: AI Model Integration
> Strategy](../../adr/adr-006-ai-integration.md) |
> [ADR‑011: Outbox Pattern](../../adr/adr-011-outbox-pattern.md) |
> [ADR‑013: Idempotency](../../adr/adr-013-idempotency.md)

## 1. Responsibility

- **1.1** Form individual learning plans (tracks), track progress and produce
  development recommendations.
- **1.2** Provide online help during interviews and AI summaries on request,
  delegating generation to AI & Parsing.

## 2. Business processes and context boundary

- **2.1** Create a long‑term learning plan (track).
- **2.2** Manage track items (courses, articles, practice).
- **2.3** Track progress.
- **2.4** Generate development recommendations from interview results and
  vacancy requirements.
- **2.5** Online help during a technical interview (answers to questions).
- **2.6** Boundary: tracks, items, progress and skills are owned here; AI
  generation itself belongs to AI & Parsing.

## 3. User stories

- **3.1 Create learning plan:** a job seeker gets a long‑term track based on
  current skills and the requirements of the desired job, to fill gaps; the plan
  is generated automatically when the desired job changes or on request.
- **3.2 Manage track:** a job seeker views the topics/courses of the track,
  marks them as completed and sees progress as a percentage.
- **3.3 Receive development recommendations:** a job seeker receives new
  recommendations (books, courses) based on interview results and the
  requirements of current vacancies.
- **3.4 AI summaries on request:** a job seeker requests an AI summary on a
  specific topic (e.g. “SOLID principles”) from the learning interface.
- **3.5 Online help on interview:** a job seeker receives hints and answers to
  questions in real time during a technical interview (text chat or voice).

## 4. Business invariants

### 4.1 General

- **4.1.1** A track is always linked to a specific desired job (`Job`).
- **4.1.2** Track progress is calculated as completed items / total items.

### 4.2 TrackItem

- **4.2.1** An item cannot be marked completed unless all previous items are
  completed (linear order).
- **4.2.2** Skipping is allowed only for optional items (`is_optional`).

## 5. Aggregates and entities

### 5.1 LearningTrack (root aggregate)

- **5.1.1 Fields:** `id`, `researcher_id`, `goal_job_id`, `created_at`, `status`
  (active/completed), `progress_percent` (derived).
- **5.1.2 Relationships:** belongs to a `Researcher` of ResearcherCrm;
  references the desired `Job`; has many `TrackItem` and, through them,
  `Progress`.
- **5.1.3 Behaviour:** `addItem()`, `markItemComplete()`, `completeTrack()`.

### 5.2 TrackItem

- **5.2.1 Fields:** `id`, `track_id`, `type` (course/article/practice), `title`,
  `resource_link`, `order_number`, `is_optional`, `status`
  (not_started/in_progress/done), `score`.
- **5.2.2 Relationships:** part of `LearningTrack`; has one `Progress`.
- **5.2.3 Behaviour:** `start()`, `complete()`, `skip()` (only if
  `is_optional`).

### 5.3 Progress

- **5.3.1 Fields:** `id`, `track_item_id`, `status`, `score`, `completed_at`.
- **5.3.2 Relationships:** part of `TrackItem`.
- **5.3.3 Behaviour:** `updateScore()`, `markDone()`.

### 5.4 Skill (lookup)

- **5.4.1 Fields:** `id`, `name`, `category`, `aliases` (list).
- **5.4.2 Relationships:** lookup entity of this context; referenced by id.
- **5.4.3 Behaviour:** none — lookup entity.

## 6. Interaction with other contexts

All inbound and outbound relationships (types, protocols, messages, purposes):
[Context Map](../../context-map.md) §2.
