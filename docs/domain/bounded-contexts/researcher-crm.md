# Bounded Context: Job Search & CRM (ResearcherCrm Service)

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.4

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [Context Map](../../context-map.md) |
> [OpenAPI](../../api/researcher-crm/openapi.yaml) |
> [AsyncAPI](../../asyncapi/events.yaml) |
> [Technical Requirements](../../technical-requirements.md) |
> [README](../../README.md)
>
> **Related ADRs:** [ADR‑002: Placing the Job Seeker (Researcher) in the
> ResearcherCrm Service](../../adr/adr-002-researcher-owner.md) |
> [ADR‑011: Outbox Pattern](../../adr/adr-011-outbox-pattern.md) |
> [ADR‑013: Idempotency](../../adr/adr-013-idempotency.md) |
> [ADR‑016: Logical data isolation for
> jobseekers](../../adr/adr-016-multitenancy.md)

## 1. Responsibility

- **1.1** Own the job seeker profile, the desired-jobs list, replies, meetings,
  messages and reply analytics.
- **1.2** Be the single source of truth for the job seeker's personal data: the
  vacancy catalogue and AI generation belong to other contexts.

## 2. Business processes and context boundary

- **2.1** Manage the job seeker profile.
- **2.2** Maintain the desired-jobs list (references `Job` of Vacancy
  Management).
- **2.3** Apply to a vacancy and withdraw an application.
- **2.4** Schedule and cancel meetings with interviewers.
- **2.5** Exchange messages.
- **2.6** Reply analytics (conversion, average time to invitation).

## 3. User stories

- **3.1 Manage profile:** a job seeker creates and edits the profile (resume,
  contacts) so that the system can suggest relevant vacancies.
- **3.2 Create desired jobs:** a job seeker adds a desired job (position,
  salary, location) and tracks its status (active, filled, archived).
- **3.3 Apply to vacancy:** a job seeker applies with one click and can withdraw
  the application; the system records the status (pending, approved, rejected,
  withdrawn) and the interview stage.
- **3.4 Schedule meetings:** a job seeker schedules an interview with an
  interviewer, receives notifications and can cancel the meeting with a reason;
  the system sends the invitation to Google Calendar asynchronously and keeps
  the meeting status (scheduled, completed, cancelled).
- **3.5 Exchange messages:** a job seeker exchanges messages with an interviewer
  within a specific meeting or vacancy.
- **3.6 Reply analytics:** a job seeker sees statistics of applications
  (invitations, rejections, pending) to evaluate the search strategy.
- **3.7 Export and delete data:** a job seeker exports all personal data and can
  delete the account with its history (right to be forgotten).

## 4. Business invariants

### 4.1 General

- **4.1.1** A job seeker can apply to a vacancy only once.
- **4.1.2** A new application to the same vacancy is possible only as a new
  application record.

### 4.2 Reply

- **4.2.1** An application can be withdrawn only in `pending` status; after
  withdrawal it becomes `withdrawn` and read-only.
- **4.2.2** An application cannot be changed after it reaches `rejected`,
  `approved` or `withdrawn` (read-only).

### 4.3 Meet

- **4.3.1** A meeting can be scheduled only after the application has moved to
  `approved` status.

## 5. Aggregates and entities

### 5.1 Researcher (root aggregate)

- **5.1.1 Fields:** `id`, `full_name`, `email`, `phone`, `resume_link`,
  `desired_job_ids`, `reply_ids`, `ai_resume`, `created_at`, `updated_at`,
  `version`.
- **5.1.2 Relationships:** has many `Reply`, `Meet`, `Message` and
  `AIRecommendation`; owns the desired-jobs list, which references `Job` of
  Vacancy Management.
- **5.1.3 Behaviour:** `updateProfile()`, `addDesiredJob()`,
  `removeDesiredJob()`, `addReply()`, `withdrawReply()`.

### 5.2 Desired Job (reference entity)

- **5.2.1 Fields:** `id`, `researcher_id`, `job_id` (a `Job` of Vacancy
  Management), `priority` (1–5), `status` (active/filled/archived),
  `custom_notes`, `ai_resume`, `timestamp`.
- **5.2.2 Relationships:** belongs to `Researcher`; references `Job` of
  [Vacancy Management](vacancies-market.md) §5.2.
- **5.2.3 Behaviour:** `archive()`, `markAsFilled()`.

### 5.3 Reply

- **5.3.1 Fields:** `id`, `researcher_id`, `vacancy_id`, `applied_at`, `status`
  (pending/approved/rejected/withdrawn), `interview_stage`, `timestamp`.
- **5.3.2 Relationships:** belongs to `Researcher`; references `Vacancy` of
  Vacancy Management.
- **5.3.3 Behaviour:** `approve()`, `reject()`, `withdraw()`.

### 5.4 Meet

- **5.4.1 Fields:** `id`, `researcher_id`, `interviewer_id`, `vacancy_id`,
  `planned_datetime`, `status` (scheduled/completed/cancelled), `feedback`,
  `timestamp`.
- **5.4.2 Relationships:** belongs to `Researcher`; references `Interviewer` and
  `Vacancy` of Vacancy Management; has many `Message`.
- **5.4.3 Behaviour:** `complete()`, `cancel()`.

### 5.5 Message

- **5.5.1 Fields:** `id`, `meet_id` (nullable), `researcher_id`,
  `interviewer_id`, `sender_type`, `content`, `timestamp`.
- **5.5.2 Relationships:** belongs to `Meet` when `meet_id` is set and to
  `Researcher`; the counterpart is an `Interviewer` of Vacancy Management.
- **5.5.3 Behaviour:** none — a message is created once and not modified.

### 5.6 AIRecommendation

- **5.6.1 Fields:** `id`, `researcher_id`, `target_type`
  (vacancy/job/resume/preparation), `target_id`, `text`, `generated_at`,
  `prompt`.
- **5.6.2 Relationships:** belongs to `Researcher`; generated by AI & Parsing
  (Parsing&AIConnector).
- **5.6.3 Behaviour:** none — recommendations are read-only in this context.

## 6. Interaction with other contexts

All inbound and outbound relationships (types, protocols, messages, purposes):
[Context Map](../../context-map.md) §2.
