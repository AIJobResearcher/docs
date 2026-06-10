# Bounded Context: Vacancy Management (Vacancies Service)

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [README](../../README.md)

## Responsibility

Manage vacancies, employers, interviewers; import data from external portals
(LinkedIn, Djinni, etc.).

## Key NFRs

- Vacancy search latency p95 ≤ 300 ms
- Availability 99.9%
- Peak load handling up to 20k RPS

## Business processes

- Import vacancies, employers and interviewers from external portals
- Track vacancy updates (change of text, salary, publication date)
- Link interviewers to vacancies

## User stories

1. **Import vacancies**

   - As a system, I want to regularly parse external portals to fill the database
     with current vacancies without manual entry.
   - As an administrator, I want to manually trigger a full or incremental import
     for a specific portal.

2. **Update existing vacancies**

   - As a system, when parsing again, I must detect changes in a vacancy (text,
     requirements, salary, publication date) and update the record in the system,
     preserving change history.

3. **View vacancies**

   - As a job seeker, I want to view current vacancies with filtering by employer,
     requirements, location and salary, to quickly find suitable offers.

## Business invariants

- An interviewer always belongs to exactly one employer.
- A vacancy cannot exist without an employer.
- A vacancy cannot be created or changed manually in the system – only imported
  from a portal.
- If a vacancy is updated on the portal (change of text, requirements, salary) or
  reopened (new publication date), the system updates the corresponding record as
  a new version (preserving change history).
- A closed vacancy (status closed) cannot be manually reopened; but if the portal
  shows it as reopened, upon import the status changes to open and a new version
  is created.
- An imported vacancy is considered valid only if it contains a title, an employer
  and a publication date.

## Domain events

- `VacancyImported` – after successful import of a new vacancy
- `VacancyUpdated` – after a change to an existing vacancy
- `VacancyClosed` – when a vacancy is closed on the portal
- `InterviewerAssigned` – interviewer linked to a vacancy
- `ExternalPortalUnreachable` – when a portal is unreachable

## Aggregates and entities

### Employer (root aggregate)

- Fields: `id`, `name`, `description`, `website`, `contacts` (email, phone),
  `portal_id`, `timestamp`
- Behaviour: `addVacancy()`, `removeVacancy()`, `addInterviewer()`,
  `removeInterviewer()`

### Vacancy (part of Employer but a separate root for search)

- Fields: `id`, `employer_id`, `title`, `description`, `requirements` (list),
  `salary` (min, max, currency), `status` (open/closed), `country`, `city`,
  `created_at`, `updated_at`, `version`
- Behaviour: `close()`, `updateDescription()`, `updateRequirements()`

### Interviewer

- Fields: `id`, `employer_id`, `full_name`, `position`, `email`, `portal_id`,
  `profile_url`, `vacancy_ids` (list), `contacts`
- Behaviour: `assignToVacancy()`, `unassignFromVacancy()`

### Portal (lookup)

- Fields: `id`, `name`, `base_url`, `api_endpoint`, `parsing_config` (JSON),
  `crawl_delay_seconds`

## Interaction with other contexts

- **Upstream:** Parsing&AIConnector (imports vacancies)
- **Downstream:** Researcher CRM (receives vacancy and interviewer events)
- **Downstream:** Search Engine (indexes vacancies via events)

## Implementation

- Service: `Vacancies`
- Technologies: PHP 8.3, Laravel 11, PostgreSQL 16, Redis
