# Bounded Context: Learning Management (KnowledgeCenter Service)

> **Related documentation:** [Glossary](../glossary.md) |
> [Architecture Overview](../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [README](../README.md)

## Responsibility

Form individual learning plans (tracks), track progress, skill development
recommendations, online help during interviews.

## Key NFRs

- Learning plan retrieval latency p95 ≤ 500 ms
- Availability 99.5%
- Integration with AI for summary generation

## Business processes

- Create long‑term learning plan (track)
- Manage track items (courses, articles, practice)
- Track progress
- Generate development recommendations based on interview results and vacancy
  analysis
- Online help during technical interview (providing answers to questions)

## User stories

1. **Create learning plan**

   - As a job seeker, I want to get a long‑term learning plan (track) based on my
     current skills and the requirements of my desired job, to fill gaps and
     increase my chances of employment.
   - The plan is generated automatically when the desired job changes or on user
     request.

2. **Manage track**

   - As a job seeker, I want to view the list of topics/courses in my track, mark
     them as completed, see progress as a percentage.

3. **Receive development recommendations**

   - As a job seeker, I want to receive new development recommendations (e.g.,
     which books to read, which courses to take) based on analysis of my interview
     results (from Researcher CRM) and requirements of current vacancies.

4. **AI summaries on request**

   - As a job seeker, I want to request an AI summary on a specific topic (e.g.,
     “SOLID principles”) directly from the learning interface, to quickly review
     material before an interview.

5. **Online help on interview**

   - As a job seeker, I want to receive hints and answers to questions in real time
     during a technical interview (via text chat or voice) to increase my chances
     of success.

## Business invariants

- A track is always linked to a specific desired job (Job).
- A track item cannot be marked “completed” unless all previous items are completed
  (linear order). Skipping items (e.g., “optional”) is allowed if permitted by
  track settings.
- Track progress is calculated as completed items / total items.

## Domain events

- `LearningTrackCreated`, `LearningTrackCompleted`
- `ProgressUpdated`
- `DevelopmentRecommendationGenerated`
- `AIConspectGenerated` – for summaries on request

## Aggregates and entities

### LearningTrack (root)

- Fields: `id`, `researcher_id`, `goal_job_id`, `created_at`, `status`
  (active/completed), `progress_percent` (derived)
- Behaviour: `addItem()`, `markItemComplete()`, `completeTrack()`

### TrackItem

- Fields: `id`, `track_id`, `type` (course/article/practice), `title`,
  `resource_link`, `order_number`, `is_optional`, `status`
  (not_started/in_progress/done), `score`
- Behaviour: `start()`, `complete()`, `skip()` (only if is_optional)

### Progress

- Fields: `id`, `track_item_id`, `status`, `score`, `completed_at`
- Behaviour: `updateScore()`, `markDone()`

### Skill (lookup)

- Fields: `id`, `name`, `category`, `aliases` (list)

## Interaction with other contexts

- **Upstream:** Researcher CRM (reply and meeting events)
- **Upstream:** Parsing&AIConnector (AI summaries)
- **Downstream:** Researcher CRM (learning recommendations)

## Implementation

- Service: `KnowledgeCenter`
- Technologies: Go 1.22, Gin, PostgreSQL 16, RabbitMQ
