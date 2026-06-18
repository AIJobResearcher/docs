# Bounded Context: Job Search & CRM (ResearcherCrm Service)

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [README](../../README.md)

## Responsibility

Manage job seeker profile, desired jobs, replies, meetings, messages, analytics.

## Key NFRs

- Meeting creation latency p95 ≤ 400 ms
- Reply consistency (eventual consistency ≤ 5 s)
- Audit of all sensitive operations

## Business processes

- Manage job seeker profile
- Create list of desired jobs
- Apply to vacancy (and withdraw application)
- Schedule meetings with interviewers (including cancellation)
- Exchange messages
- Reply analytics (conversion, average time to invitation)

## User stories

1. **Manage profile**

   - As a job seeker, I want to create and edit my profile (resume, contacts) so
     that the system can suggest relevant vacancies.

2. **Create desired jobs**

   - As a job seeker, I want to add a “desired job” (set of criteria: position,
     salary, location) and track its status (active, filled, archived).

3. **Apply to vacancy**

   - As a job seeker, I want to apply to a vacancy with one click to start the
     interview process.
   - As a job seeker, I want to withdraw my application if I change my mind or find
     another job, so as not to clutter the interview process.
   - As a system, I want to record the status of the application (pending, approved,
     rejected, withdrawn) and the interview stage.

4. **Schedule meetings**

   - As a job seeker, I want to schedule an interview with an interviewer (choosing
     a date and time) and receive notifications.
   - As a job seeker, I want to cancel a scheduled meeting (with a reason) to free
     up time and notify the other party.
   - As a system, I want to automatically send an invitation to Google Calendar
     (asynchronously) and update the meeting status (scheduled, completed,
     cancelled).

5. **Exchange messages**

   - As a job seeker, I want to exchange messages with an interviewer within a
     specific meeting or vacancy.

6. **Reply analytics**

   - As a job seeker, I want to see statistics of my applications (how many
     invitations, rejections, pending) to evaluate the effectiveness of my search
     strategy.

7. **Export and delete data**

   - As a job seeker, I want to export all my data to PDF and/or completely delete
     my account with history, to comply with the “right to be forgotten”.

## Business invariants

- A job seeker can apply to a vacancy only once.
- A job seeker can withdraw an application only in the “pending” status. After
  withdrawal, the application goes to “withdrawn” status and becomes read‑only.
  A new application to the same vacancy is possible only as a new application.
- A meeting can be scheduled only after the application has moved to “approved”
  status.
- An application cannot be changed after it has moved to “rejected”, “approved”
  or “withdrawn” (read‑only).

## Domain events

- `ResearcherRegistered`
- `JobPreferencesUpdated`
- `ReplyCreated`, `ReplyWithdrawn`
- `MeetScheduled`, `MeetCompleted`, `MeetCancelled`
- `MessageSent`
- `AccountDeleted`, `DataExported`

## Aggregates and entities

### Researcher (root)

- Fields: `id`, `full_name`, `email`, `phone`, `resume_link`, `desired_job_ids`,
  `reply_ids`, `ai_resume`, `created_at`, `updated_at`, `version`
- Behaviour: `updateProfile()`, `addDesiredJob()`, `removeDesiredJob()`, `addReply()`,
  `withdrawReply()`

### Job (desired job)

- Fields: `id`, `researcher_id`, `title`, `vacancy_ids` (link), `priority`,
  `status` (active/filled/archived), `custom_notes`, `ai_resume`, `timestamp`
- Behaviour: `archive()`, `markAsFilled()`

### Reply

- Fields: `id`, `researcher_id`, `vacancy_id`, `applied_at`, `status`
  (pending/approved/rejected/withdrawn), `interview_stage`, `timestamp`
- Behaviour: `approve()`, `reject()`, `withdraw()`

### Meet

- Fields: `id`, `researcher_id`, `interviewer_id`, `vacancy_id`, `planned_datetime`,
  `status` (scheduled/completed/cancelled), `feedback`, `timestamp`
- Behaviour: `complete()`, `cancel()`

### Message

- Fields: `id`, `meet_id` (nullable), `researcher_id`, `interviewer_id`,
  `sender_type`, `content`, `timestamp`

### AIRecommendation

- Fields: `id`, `researcher_id`, `target_type` (vacancy/job/resume/preparation),
  `target_id`, `text`, `generated_at`, `prompt`

## Interaction with other contexts

- **Upstream:** Vacancies (vacancy and interviewer events)
- **Upstream:** Parsing&AIConnector (AI recommendations)
- **Downstream:** KnowledgeCenter (reply and meeting events for learning)
- **Downstream:** Search Engine (for analytics)

## Implementation

- Service: `ResearcherCrm`
- Technologies: PHP 8.5, Symfony 7.1, Doctrine ORM, PostgreSQL 16, Redis
