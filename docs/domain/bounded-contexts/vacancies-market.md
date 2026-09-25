# Bounded Context: Vacancy Management (Vacancies Market Service)

**Status:** accepted
**Date:** 2026-09-25
**Version:** 1.16

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

## 1. Responsibility

- **1.1** Own the canonical, read-optimized catalogue of jobs, vacancies,
  employers, interviewers, requirements, portals and locations.
- **1.2** Atomically persist catalogue changes requested by `Parsing&AIConnector`.
- **1.3** Enforce data-integrity and concurrency constraints; never make
  parsing, normalization or duplicate-resolution decisions (see 5.1).
- **1.4** Provide read access to the catalogue and publish committed changes
  for other contexts and search indexes.

## 2. Key NFRs

- **2.1** Vacancy search latency p95 ≤ 300 ms.
- **2.2** Availability 99.9%.
- **2.3** Peak load handling up to 20k RPS.

## 3. Business processes

- **3.1** Receive complete catalogue-change requests from `Parsing&AIConnector`.
- **3.2** Validate them and apply the requested create, update, merge or close
  in one local transaction, persisting the supplied source provenance and
  aggregate version.
- **3.3** Expose catalogue data through the read API and keep its search read
  model current.

## 4. User stories

- **4.1 Persist an approved catalogue change:** apply the parser's create,
  update, merge or close atomically, keep the supplied source provenance and
  merge result, reject invalid or stale requests as retryable without changing
  the catalogue.
- **4.2 View vacancies:** a jobseeker browses current vacancies matching their
  desired jobs, filtering by employer, requirements, location and salary.
- **4.3 Manage requirements:** an administrator creates, updates and deletes
  `Requirement` entries; new entries may also arrive with an approved change.

## 5. Context boundary and integration contract

- **5.1** `Parsing&AIConnector` is upstream for all catalogue-enrichment
  decisions. It owns portal configuration, schedules, parsing modes, rate
  limits, `robots.txt`, proxy use, external-format mapping, requirement
  normalization and AI-assisted duplicate matching. It keeps the raw and
  staging data needed to make those decisions.
- **5.2** To match against existing catalogue entries without writing another
  service's database, `Parsing&AIConnector` maintains a local projection from
  published catalogue events. It sends a `CatalogueChangeRequested` command
  over RabbitMQ only after choosing the target record and requested operation.
- **5.3** `Vacancies Market` does not recalculate the result. The command
  carries an idempotency identifier, mutation type, target aggregate ID,
  expected version, canonical data, source provenance and merge identifiers;
  the service validates only the contract and local data integrity (see 11.2).
- **5.4** After a local transaction succeeds, this context publishes its own
  domain events. Consumers use these events to update CRM projections, search
  indexes and RAG documents.

## 6. Business invariants

### 6.1 General

- **6.1.1** A vacancy cannot be created or changed through the public catalogue
  API. It is created or updated only by applying an approved
  `CatalogueChangeRequested` command.
- **6.1.2** A vacancy cannot exist without an employer.
- **6.1.3** A change request is accepted only if its canonical vacancy data
  contains a title, an employer, a publication date (`VacancySource.posted_at`)
  and at least one Job.

### 6.2 Vacancy

- **6.2.1** An approved update or reopen creates a new aggregate version,
  preserving history.
- **6.2.2** A closed vacancy cannot be manually reopened. It can be reopened
  only by an approved `CatalogueChangeRequested` command.
- **6.2.3** The parser decides when source closures require a canonical vacancy
  to close; this context persists that decision without recalculating source
  state.
- **6.2.4** Applying an update requires the command's `expected_version` to
  match the current aggregate version. A conflict is rejected as retryable,
  preventing lost updates.
- **6.2.5** Each Vacancy must have at least one source with an `external_url`
  (`VacancySource`). A vacancy cannot exist without a portal source.
- **6.2.6** An accepted request updates the supplied `VacancySource`
  provenance, including `last_seen_at`, regardless of whether canonical fields
  changed.
- **6.2.7** A Vacancy may be assigned to one, or multiple Jobs via
  `VacancyJobAssignment`.
- **6.2.8** A Vacancy may reference many Requirements via
  `VacancyRequirementAssignment`.
- **6.2.9** On update, a supplied `requirements` key replaces the current set:
  Requirements missing from it are unassigned. An absent `requirements` key
  leaves the set unchanged.
- **6.2.10** A merge unions the Requirement assignments of the merged source
  vacancy into the surviving vacancy.
- **6.2.11** A duplicate Requirement inside one command is skipped, not
  rejected.

### 6.3 Salary

- **6.3.1** If `max_salary` is provided, it must be ≥ 0.
- **6.3.2** If `min_salary` is not provided, it defaults to 0.
- **6.3.3** If both `min_salary` and `max_salary` are provided, `max_salary`
  must be ≥ `min_salary`.

### 6.4 Employer persistence

- **6.4.1** If an approved change request includes a previously unknown
  employer, the same transaction creates it. If its required employer data is
  missing, reject the request with a clear validation error.

### 6.5 Interviewer (business rules)

- **6.5.1** An interviewer is a child entity of exactly one Employer and has no
  `employer_id` of its own.

### 6.6 Job

- **6.6.1** A Job cannot be deleted if it is referenced by any active Vacancy
  (via `VacancyJobAssignment`).

### 6.7 Requirement (shared dictionary)

- **6.7.1** All Requirements live in a shared dictionary; Job and Vacancy
  reference them by ID, not by string value.
- **6.7.2** Requirement normalization and identification are decided by
  `Parsing&AIConnector`. This context only persists the Requirement IDs and new
  definitions supplied by the approved command.
- **6.7.3** A Requirement cannot be deleted if it is referenced by any active
  Job or Vacancy.

### 6.8 Relationship / Mapping constraints

- **6.8.1** A Job can reference the same Requirement only once (via
  `JobRequirementAssignment`).
- **6.8.2** A Vacancy can reference the same Requirement only once (via
  `VacancyRequirementAssignment`).
- **6.8.3** A Vacancy can be assigned to the same Job only once while active
  (via `VacancyJobAssignment`). To reassign, first unassign the existing
  assignment.
- **6.8.4** A Vacancy keeps at least one Job: unassigning its last Job is
  rejected (see 6.2.7).

## 7. Domain events published by this context

- **7.1** These events report a successful change to data owned by `Vacancies
  Market`. They are not parser-status events.

| Event | Published when |
| --- | --- |
| `EmployerImported` | A previously unknown employer is added to the catalogue. |
| `VacancyImported` | A previously unknown canonical vacancy is created. |
| `VacancyUpdated` | A canonical vacancy changes or is reopened. |
| `VacancyMerged` | Parser-selected duplicates are merged into one canonical vacancy. |
| `VacancyClosed` | A canonical vacancy is closed after source data confirms it. |

- **7.2** Every published event contains `event_id`, `event_type`,
  `event_version`, `aggregate_id`, `timestamp`, `correlation_id` and
  event-specific `data`. Compatibility rules are defined in
  [ADR‑012](../../adr/adr-012-event-versioning.md); published event schemas
  belong in [AsyncAPI](../../asyncapi/events.yaml).
- **7.3** `event_id` identifies the event instance and never equals
  `aggregate_id` (the source aggregate, shared by its events); idempotency must
  not rely on them matching (see 11.2).
- **7.4** Parser status events (`ExternalPortalUnreachable`,
  `PortalStructureChanged`, parser-run lifecycle) belong to
  `Parsing&AIConnector`.

## 8. Aggregates and entities

### 8.1 Requirement (shared dictionary / reference entity)

- **8.1.1 Type:** Lookup entity (not a root aggregate, managed as a reference).
- **8.1.2 Fields:** `id` (UUID), `title` (string, unique, case-insensitive),
  `description` (string, nullable), `category` (string, nullable — e.g.,
  "technical", "soft-skill", "language", "education"), `created_at` (timestamp),
  `updated_at` (timestamp).
- **8.1.3 Behavior:** `addRequirement()`, `updateRequirement()`.
- **8.1.4** Deletion is handled in the application layer: a delete-Requirement
  use case calls
  `RequirementRepositoryInterface::isReferencedByActiveVacancyOrJob()` and
  rejects deletion while any active Job or Vacancy references the Requirement
  (see 6.7.3).

### 8.2 Job (root aggregate)

- **8.2.1 Fields:** `id` (UUID), `title` (string), `category` (string),
  `sub_category` (string, nullable), `parent_job_id` (UUID, nullable,
  self-reference), `description` (text, nullable), `created_at` (timestamp),
  `updated_at` (timestamp), `version` (integer, default 1), `deleted_at`
  (timestamp, nullable).
- **8.2.2 Relationships:** has many `Requirement` via many-to-many table
  `job_requirements`.
- **8.2.3 Behavior:** `addJob()`, `updateJob()`, `deleteJob()` (soft delete —
  sets `deleted_at`), `addRequirement()`, `removeRequirement()`.
- **8.2.4** The guard that no active Vacancy references this Job is enforced by
  the delete-Job use case (application layer) via
  `JobRepositoryInterface::hasActiveVacancyAssignments()` before calling
  `deleteJob()` (see 6.6.1).

### 8.3 Employer (root aggregate)

- **8.3.1 Fields:** `id` (UUID), `portal_id` (UUID, references `Portal`),
  `title` (string), `description` (text, nullable), `website` (string,
  nullable), `email` (string, nullable), `phone` (string, nullable),
  `logo_url` (string, nullable — URL/path to the employer logo; server path
  now, S3 later), `location_ids` (`list<int>`, references `Location`),
  `created_at` (timestamp), `updated_at`
  (timestamp), `version` (integer, default 1).
- **8.3.2 Behavior:** `addVacancy()`, `removeVacancy()` (only if vacancy is
  closed), `addInterviewer()`, `removeInterviewer()`.

### 8.4 Vacancy (part of Employer)

- **8.4.1 Fields:** `id` (UUID), `employer_id` (UUID), `title` (string),
  `min_salary` (integer, USD, default 0), `max_salary` (integer, USD,
  nullable), `status` (enum: open/closed), `created_at` (timestamp),
  `updated_at` (timestamp), `employment_type` (enum:
  part-time/contract/internship/full-time/volunteer), `workplace` (enum:
  remote/on-site/hybrid), `researcher_location_ids` (`list<int>`, references
  `Location`), `version` (integer, default 1), `closed_at` (timestamp,
  nullable).
- **8.4.2 Relationships:** has many `Requirement` via many-to-many table
  `vacancy_requirements`; is assigned to at least one `Job` via
  `VacancyJobAssignment` (many-to-many).
- **8.4.3 Behavior:** `closeVacancy()`, `assignToJob()`, `unassignFromJob()`,
  `addRequirement()`, `removeRequirement()`.
- **8.4.4 Note:** Salary is stored in USD only. Multi-currency support is
  planned for a future version.

### 8.5 Interviewer (part of Employer)

- **8.5.1 Fields:** `id` (UUID), `full_name` (string), `position` (string,
  nullable), `profile_urls` (JSON, nullable — e.g.,
  `{"Linkedin": "...", "DOU": "..."}`),
  `avatar_url` (string, nullable — URL/path to the interviewer photo; server
  path now, S3 later), `created_at` (timestamp), `updated_at` (timestamp),
  `version` (integer, default 1), `is_active` (boolean, default true),
  `deleted_at` (timestamp, nullable).
- **8.5.2 Behavior:** `updateInterviewer()`.

### 8.6 Portal (external portal lookup)

- **8.6.1** Owns the `Portal` reference entity representing the external job
  portals the catalogue originates from.
- **8.6.2 Type:** reference/lookup entity; not a root aggregate.
- **8.6.3 Fields:** `id` (UUID), `code` (string, unique — the `source_key`
  value such as `linkedin`, `djinni`), `name` (string), `base_url` (string,
  nullable), `created_at` (timestamp), `updated_at` (timestamp).
- **8.6.4 Relationship:** `Employer.portal_id` references a `Portal` by UUID;
  an Interviewer inherits the Portal through its Employer. A Vacancy's origin
  is tracked per source via `VacancySource.source_key`, not via `portal_id`.
- **8.6.5 Behavior:** `addPortal()`, `updatePortal()`, `deletePortal()` —
  delete is allowed only while no Employer references the Portal.
- **8.6.6 Ownership boundary:** portal identity and reference integrity belong
  here; parsing configuration and lifecycle belong to `Parsing&AIConnector`
  (see ADR‑007).

### 8.7 Mapping Tables (not root aggregates)

> **Note:** Business constraints for these tables are documented in [Business
> invariants, section 6.8](#68-relationship--mapping-constraints).

- **8.7.1 JobRequirementAssignment — Fields:** `id` (UUID), `job_id` (UUID),
  `requirement_id` (UUID), `assigned_at` (timestamp), `version` (integer,
  default 1).
- **8.7.2 VacancyRequirementAssignment — Fields:** `id` (UUID), `vacancy_id`
  (UUID), `requirement_id` (UUID), `assigned_at` (timestamp), `version`
  (integer, default 1).
- **8.7.3 VacancyJobAssignment — Fields:** `id` (UUID), `vacancy_id` (UUID),
  `job_id` (UUID), `assigned_at` (timestamp), `relevance_score` (integer,
  nullable, 1-100), `version` (integer, default 1).
- **8.7.4 VacancySource (source provenance) — Fields:** `id` (UUID),
  `vacancy_id` (UUID), `portal_id` (UUID, references `Portal`), `source_key`
  (string, e.g., `linkedin`), `external_vacancy_id` (string), `external_url`
  (string), `title` (string), `description` (text, nullable), `posted_at`
  (timestamp), `first_seen_at` (timestamp), `last_seen_at` (timestamp),
  `closed_at` (timestamp, nullable), `is_primary` (boolean, default false).
  **Purpose:** source provenance for the read API, audit history and the
  parser's local projection.

### 8.8 Location

- **8.8.1 Type:** reference/lookup entity; not a root aggregate.
- **8.8.2 Fields:** `id` (int), `name` (string(255)), `iso_name` (string(5), nullable),
  `parent_id` (int, nullable — self-reference), `type` (enum:
  country/city/unification-of-countries/region).

## 9. Interaction with other contexts

| Context | Relationship | Protocol | Responsibility at this boundary |
| --- | --- | --- | --- |
| Parsing&AIConnector | Upstream, Customer-Supplier | RabbitMQ | Supplies approved catalogue-change commands; owns parsing, normalization and duplicate decisions. |
| ResearcherCrm | Downstream, Publisher-Subscriber | RabbitMQ | Receives committed vacancy and merge changes for replies and meetings. |
| Search Engine | Downstream, Publisher-Subscriber | RabbitMQ | Builds read indexes from vacancy and employer changes. |
| Frontend | Downstream, REST consumer | REST | Searches and reads public catalogue data. |

- **9.1** The service has no shared database or shared domain model with these
  contexts. It exposes only its REST and event contracts.

## 10. Implementation

- **10.1 Service:** `vacancies-market`.
- **10.2 Technologies:** PHP 8.5, Laravel 13, PostgreSQL 16, Redis.

## 11. Outbox & Idempotency (implementation notes)

- **11.1** All outbound domain events (`VacancyImported`, `VacancyUpdated`,
  `VacancyClosed`, etc.) must be written to `outbox_messages` in the same
  transaction as the aggregate change.
- **11.2** The consumer of `CatalogueChangeRequested` commands must use
  `processed_events`, with `event_id` as its primary key, before applying a
  change.
- **11.3** Identify source provenance by `(source_key, external_vacancy_id)`.
