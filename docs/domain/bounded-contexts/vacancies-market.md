# Bounded Context: Vacancy Management (Vacancies Market Service)

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [Context Map](../../context-map.md) |
> [OpenAPI](../../api/vacancies-market/openapi.yaml) |
> [AsyncAPI](../../asyncapi/events.yaml) | [README](../../README.md)
>
> **Related ADRs:** [ADR‑007: External portal parsing
> strategy](../../adr/adr-007-parsing-strategy.md) |
> [ADR‑011: Outbox Pattern](../../adr/adr-011-outbox-pattern.md) |
> [ADR‑013: Idempotency](../../adr/adr-013-idempotency.md) |
> [ADR‑014: OpenSearch](../../adr/adr-014-opensearch.md)

## Responsibility

- Own the canonical, read-optimized catalogue of jobs, vacancies, employers,
  interviewers and requirements.
- Atomically persist catalogue changes requested by `Parsing&AIConnector`.
- Enforce data-integrity and concurrency constraints without making parsing,
  normalization or duplicate-resolution decisions.
- Provide read access to the catalogue and publish its committed changes for
  other contexts and search indexes.

`Vacancies Market` does not access external portals, plan scans, interpret HTML
or JSON from portals, normalize data or find duplicate vacancies. Those
responsibilities, including AI-assisted matching and the resulting catalogue
change decision, belong to `Parsing&AIConnector` and its ACL.

## Key NFRs

- Vacancy search latency p95 ≤ 300 ms
- Availability 99.9%
- Peak load handling up to 20k RPS

## Business processes

- Receive complete catalogue-change requests from `Parsing&AIConnector`.
- Validate their structural, referential and concurrency constraints, then apply
  the requested create, update, merge or close operation in a local transaction.
- Persist the source provenance, required aggregates and aggregate version
  supplied by the accepted request.
- Expose catalogue data through the read API and keep its search read model
  current.

## User stories

1. **Persist an approved catalogue change**
    - As a system, I want to atomically apply the parser's approved create,
      update, merge or close request to the corresponding catalogue records.
    - As a system, I must retain the source provenance and supplied merge result
      without recalculating duplicate candidates or similarity scores.
    - As a system, I must reject an invalid or stale request without changing the
      catalogue and report a retryable error to the sender.

2. **Update existing vacancies**
    - As a system, when the parser approves a vacancy change (text,
      requirements, salary, publication date), I must persist it while
      preserving change history.

3. **View vacancies**
    - As a jobseeker, I want to browse current vacancies matching my stated job
      desires, filtering them by employer, requirements, location, and salary to
      quickly find suitable offers.

4. **Manage requirements**
    - As an administrator, I want to view, create, update, and delete
      Requirement entries in the shared dictionary.
    - As a system, I want to persist new Requirement entries included in an
      approved catalogue-change request.

## Context boundary and integration contract

`Parsing&AIConnector` is upstream for all catalogue-enrichment decisions. It
owns portal configuration, schedules, parsing modes, rate limits, `robots.txt`,
proxy use, external-format mapping, requirement normalization and AI-assisted
duplicate matching. It keeps the raw and staging data needed to make those
decisions.

To match against existing catalogue entries without writing another service's
database, `Parsing&AIConnector` maintains a local projection from published
catalogue events. It sends a `CatalogueChangeRequested` command over RabbitMQ
only after choosing the target record and requested operation.

`Vacancies Market` receives this command and does not recalculate the result.
The command must include an idempotency identifier, mutation type, target
aggregate ID when applicable, expected version, complete canonical data, source
provenance and the requested merge identifiers. The service validates only the
command contract and local data integrity before persisting it.

After a local transaction succeeds, this context publishes its own domain
events. Consumers use these events to update CRM projections, search indexes
and RAG documents.

## Business invariants

### General

- A vacancy cannot be created or changed through the public catalogue API. It is
  created or updated only by applying an approved `CatalogueChangeRequested`
  command.
- A vacancy cannot exist without an employer.
- A change request is accepted only if its canonical vacancy data contains a
  title, an employer and a publication date.

### Vacancy

- An approved update or reopen creates a new aggregate version, preserving
  history.
- A closed vacancy cannot be manually reopened. It can be reopened only by an
  approved `CatalogueChangeRequested` command.
- The parser decides when source closures require a canonical vacancy to close;
  this context persists that decision without recalculating source state.
- Applying an update requires the command's `expected_version` to match the
  current aggregate version. A conflict is rejected as retryable, preventing
  lost updates.
- Each Vacancy must have at least one external URL (portal source). A vacancy
  cannot exist without a portal source.
- An accepted request updates the supplied `VacancySource` provenance,
  including `last_seen_at`, regardless of whether canonical fields changed.
- Duplicate detection and merge selection are not business rules of this
  context. It persists the merge requested by `Parsing&AIConnector` only after
  validating local references and optimistic locking.
- A Vacancy may be assigned to zero, one, or multiple Jobs via
  `VacancyJobAssignment`.

### Salary

- If `max_salary` is provided, it must be ≥ 0.
- If `min_salary` is not provided, it defaults to 0.
- If both `min_salary` and `max_salary` are provided, `max_salary` must be
  ≥ `min_salary`.

### Employer persistence

- If an approved change request includes a previously unknown employer, the same
  transaction creates it. If its required employer data is missing, reject the
  request with a clear validation error.

### Interviewer (business rules)

- An interviewer always belongs to exactly one employer.
- When assigning an interviewer to a vacancy, the system must verify that the
  interviewer's `employer_id` matches the vacancy's `employer_id`.

### Job

- A Job cannot be deleted if it is referenced by any active Vacancy (via
  `VacancyJobAssignment`).

### Requirement (shared dictionary)

- All Requirements are stored in a shared dictionary (Requirement entity). Job
  and Vacancy reference Requirements by ID, not by string value. This ensures
  consistency, enables fast filtering, and simplifies analytics.
- Requirement normalization and identification are decided by
  `Parsing&AIConnector`. This context only persists the Requirement IDs and new
  definitions supplied by the approved command.
- A Requirement cannot be deleted if it is referenced by any active Job or
  Vacancy.

### Relationship / Mapping constraints

- A Job can reference the same Requirement only once (via
  `JobRequirementAssignment`).
- A Vacancy can reference the same Requirement only once (via
  `VacancyRequirementAssignment`).
- A Vacancy can be assigned to the same Job only once while active (via
  `VacancyJobAssignment`). To reassign, first unassign the existing
  assignment.
- An interviewer can be assigned to the same vacancy only once while
  `unassigned_at` is null (via `InterviewerVacancyAssignment`). To reassign,
  first unassign.
- Assignment of an interviewer to a vacancy is allowed only if the
  interviewer's `employer_id` matches the vacancy's `employer_id`.

## Domain events published by this context

These events report a successful change to data owned by `Vacancies Market`.
They are not parser-status events.

| Event | Published when |
| --- | --- |
| `EmployerImported` | A previously unknown employer is added to the catalogue. |
| `VacancyImported` | A previously unknown canonical vacancy is created. |
| `VacancyUpdated` | A canonical vacancy changes or is reopened. |
| `VacancyMerged` | Parser-selected duplicates are merged into one canonical vacancy. |
| `VacancyClosed` | A canonical vacancy is closed after source data confirms it. |
| `InterviewerAssigned` | An interviewer is linked to a vacancy. |

Every published event contains `event_id`, `event_type`, `event_version`,
`aggregate_id`, `timestamp`, `correlation_id` and event-specific `data`.
Compatibility rules are defined in
[ADR‑012](../../adr/adr-012-event-versioning.md); published event schemas belong
in [AsyncAPI](../../asyncapi/events.yaml).

`ExternalPortalUnreachable`, `PortalStructureChanged` and parser-run lifecycle
events are owned and published by `Parsing&AIConnector`; they are intentionally
not domain events of this context.

## Aggregates and entities

### Requirement (shared dictionary / reference entity)

- **Type:** Lookup entity (not a root aggregate, managed as a reference)
- Fields: `id` (UUID), `title` (string, unique, case‑insensitive),
  `description` (string, nullable), `category` (string, nullable — e.g.,
  "technical", "soft-skill", "language", "education"), `created_at`
  (timestamp), `updated_at` (timestamp)
- Behavior: `addRequirement()`, `updateRequirement()`, `removeRequirement()`

### Job (root aggregate)

- Fields: `id` (UUID), `title` (string), `category` (string),
  `sub_category` (string, nullable), `parent_job_id` (UUID, nullable,
  self‑reference), `description` (text, nullable), `created_at` (timestamp),
  `updated_at` (timestamp), `version` (integer, default 1), `deleted_at`
  (timestamp, nullable)
- Relationships: has many `Requirement` via many‑to‑many table
  `job_requirements`
- Behavior: `addJob()`, `updateJob()`, `deleteJob()` (soft delete — sets
  `deleted_at` and checks that no active Vacancy references this Job via
  `VacancyJobAssignment`), `addRequirement()`, `removeRequirement()`

### Employer (root aggregate)

- Fields: `id` (UUID), `title` (string), `description` (text, nullable),
  `website` (string, nullable), `email` (string, nullable), `phone` (string,
  nullable), `logo_url` (string, nullable), `created_at` (timestamp),
  `updated_at` (timestamp), `version` (integer, default 1)
- Behavior: `addVacancy()`, `removeVacancy()` (only if vacancy is closed),
  `addInterviewer()`, `removeInterviewer()`

### Vacancy (part of Employer but a separate root for search)

- Fields: `id` (UUID), `employer_id` (UUID), `title` (string),
  `description` (text, nullable), `min_salary` (integer, USD, default 0),
  `max_salary` (integer, USD, nullable), `status` (enum: open/closed),
  `country` (string, nullable), `city` (string, nullable), `created_at`
  (timestamp), `updated_at` (timestamp), `posted_at` (timestamp),
  `employment_type` (enum: part-time/contract/internship/full-time/volunteer),
  `workplace` (enum: remote/on-site/hybrid), `version` (integer, default 1),
  `internal_url` (string, nullable), `external_urls` (list<string>),
  `closed_at` (timestamp, nullable)
- Relationships:
  - has many `Requirement` via many‑to‑many table `vacancy_requirements`
  - has many `Job` via `VacancyJobAssignment` (many‑to‑many)
- Behavior: `closeVacancy()`, `assignToJob()`, `unassignFromJob()`,
  `addRequirement()`, `removeRequirement()`
- **Note:** Salary is stored in USD only. Multi‑currency support is planned
  for a future version.

### Interviewer

- Fields: `id` (UUID), `employer_id` (UUID), `full_name` (string),
  `position` (string, nullable), `profile_urls` (JSON, nullable — e.g.,
  `{"Linkedin": "...", "DOU": "..."}`), `created_at` (timestamp),
  `updated_at` (timestamp), `version` (integer, default 1), `is_active`
  (boolean, default true), `deleted_at` (timestamp, nullable)
- Behavior: `assignToVacancy()`, `unassignFromVacancy()`

### External source reference

This context does not own a `Portal` aggregate. Portal configuration and
lifecycle are owned by `Parsing&AIConnector`. `Vacancies Market` stores only
the source identity and URL supplied in an approved change request to explain a
catalogue record's origin.

### Mapping Tables (not root aggregates)

> **Note:** Business constraints for these tables are documented in the
> [Business invariants > Relationship / Mapping constraints](#relationship-
> mapping-constraints) section above.

#### JobRequirementAssignment

- Fields: `id` (UUID), `job_id` (UUID), `requirement_id` (UUID),
  `assigned_at` (timestamp), `version` (integer, default 1)

#### VacancyRequirementAssignment

- Fields: `id` (UUID), `vacancy_id` (UUID), `requirement_id` (UUID),
  `assigned_at` (timestamp), `version` (integer, default 1)

#### VacancyJobAssignment

- Fields: `id` (UUID), `vacancy_id` (UUID), `job_id` (UUID),
  `assigned_at` (timestamp), `relevance_score` (integer, nullable, 1-100),
  `version` (integer, default 1)

#### InterviewerVacancyAssignment

- Fields: `id` (UUID), `interviewer_id` (UUID), `vacancy_id` (UUID),
  `assigned_at` (timestamp), `unassigned_at` (timestamp, nullable),
  `version` (integer, default 1)

#### VacancySource (source provenance)

- Fields: `id` (UUID), `vacancy_id` (UUID), `source_key` (string, e.g.,
  `linkedin`), `external_vacancy_id` (string), `external_url` (string),
  `first_seen_at` (timestamp), `last_seen_at` (timestamp), `closed_at`
  (timestamp, nullable), `is_primary` (boolean, default false)
- **Purpose:** Tracks which portals a vacancy came from and when. It provides
  provenance for the read API, audit history and the parser's local projection.

## Interaction with other contexts

| Context | Relationship | Protocol | Responsibility at this boundary |
| --- | --- | --- | --- |
| Parsing&AIConnector | Upstream, Customer-Supplier | RabbitMQ | Supplies approved catalogue-change commands; owns parsing, normalization and duplicate decisions. |
| ResearcherCrm | Downstream, Publisher-Subscriber | RabbitMQ | Receives committed vacancy, merge and interviewer changes for replies and meetings. |
| Search Engine | Downstream, Publisher-Subscriber | RabbitMQ | Builds read indexes from vacancy and employer changes. |
| Frontend | Downstream, REST consumer | REST | Searches and reads public catalogue data. |

The service has no shared database or shared domain model with these contexts.
It exposes only its REST and event contracts.

## Implementation

- Service: `vacancies-market`
- Technologies: PHP 8.5, Laravel 13, PostgreSQL 16, Redis

## Outbox & Idempotency (implementation notes)

- All outbound domain events (`VacancyImported`, `VacancyUpdated`,
  `VacancyClosed`, etc.) must be written to `outbox_messages` in the same
  transaction as the aggregate change.
- The consumer of `CatalogueChangeRequested` commands must use
  `processed_events`, with `event_id` as its primary key, before applying a
  change.
- Use `(source_key, external_vacancy_id)` to identify the source provenance
  supplied by the command. It protects source-record integrity; it is not a
  duplicate-resolution algorithm in this context.
