# ADR-002: Placing the Job Seeker (Researcher) in the ResearcherCrm Service

## Context

The job seeker is a central concept for the job search process and also
participates in other domains (learning, applications). It is important to
clearly define which service owns the `Researcher` aggregate.

## Decision

The `Researcher` aggregate (job seeker) resides in the `ResearcherCrm` service.
The employer (`Employer`) and vacancies (`Vacancy`) reside in the `Vacancies`
service.
References to `researcher_id` in other services (KnowledgeCenter) are weak
(no foreign keys) and are verified through events or APIs.

## Why this decision

- `Researcher` is the root of the "Job Search & CRM" domain, where profile changes,
  applications, and meetings occur.
- Separation from the vacancy market isolates changes in vacancies (import,
  updates) from user logic.
- Follows the principle "one service – single source of truth" for the entity.

## Alternatives

- Place `Researcher` in a separate service (e.g., User Management) – would require
  many inter-service calls for each job seeker action.
- Duplicate job seeker data across several services – leads to inconsistency.

## Consequences

- All requests for job seeker data from other services go through the
  ResearcherCrm API or events.
- KnowledgeCenter stores `researcher_id` as a reference but does not own the
  profile.

## Related artifacts

- Section "Data Ownership" in `domain-model.md`.
- ADR-016 (logical isolation via `researcher_id`).
