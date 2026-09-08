# Bounded Context: Vacancy Management (Vacancies Market Service)

**Status:** accepted
**Date:** 2026-09-08
**Version:** 1.1

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
  employers, interviewers and requirements.
- **1.2** Atomically persist catalogue changes requested by `Parsing&AIConnector`.
- **1.3** Enforce data-integrity and concurrency constraints without making
  parsing, normalization or duplicate-resolution decisions.
- **1.4** Provide read access to the catalogue and publish its committed changes
  for other contexts and search indexes.
- **1.5** `Vacancies Market` does not access external portals, plan scans,
  interpret HTML or JSON from portals, normalize data or find duplicate
  vacancies. Those responsibilities, including AI-assisted matching and the
  resulting catalogue change decision, belong to `Parsing&AIConnector` and its
  ACL.

## 2. Key NFRs

- **2.1** Vacancy search latency p95 ≤ 300 ms.
- **2.2** Availability 99.9%.
- **2.3** Peak load handling up to 20k RPS.

## 3. Business processes

- **3.1** Receive complete catalogue-change requests from `Parsing&AIConnector`.
- **3.2** Validate their structural, referential and concurrency constraints,
  then apply the requested create, update, merge or close operation in a local
  transaction.
- **3.3** Persist the source provenance, required aggregates and aggregate
  version supplied by the accepted request.
- **3.4** Expose catalogue data through the read API and keep its search read
  model current.

## 4. User stories

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
- **5.3** `Vacancies Market` receives this command and does not recalculate the
  result. The command must include an idempotency identifier, mutation type,
  target aggregate ID when applicable, expected version, complete canonical
  data, source provenance and the requested merge identifiers. The service
  validates only the command contract and local data integrity before
  persisting it.
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
  contains a title, an employer and a publication date.

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
- **6.2.5** Each Vacancy must have at least one external URL (portal source). A
  vacancy cannot exist without a portal source.
- **6.2.6** An accepted request updates the supplied `VacancySource`
  provenance, including `last_seen_at`, regardless of whether canonical fields
  changed.
- **6.2.7** Duplicate detection and merge selection are not business rules of
  this context. It persists the merge requested by `Parsing&AIConnector` only
  after validating local references and optimistic locking.
- **6.2.8** A Vacancy may be assigned to zero, one, or multiple Jobs via
  `VacancyJobAssignment`.

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

- **6.5.1** An interviewer always belongs to exactly one employer.
- **6.5.2** When assigning an interviewer to a vacancy, the system must verify
  that the interviewer's `employer_id` matches the vacancy's `employer_id`.

### 6.6 Job

- **6.6.1** A Job cannot be deleted if it is referenced by any active Vacancy
  (via `VacancyJobAssignment`).

### 6.7 Requirement (shared dictionary)

- **6.7.1** All Requirements are stored in a shared dictionary (Requirement
  entity). Job and Vacancy reference Requirements by ID, not by string value.
  This ensures consistency, enables fast filtering, and simplifies analytics.
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
- **6.8.4** An interviewer can be assigned to the same vacancy only once while
  `unassigned_at` is null (via `InterviewerVacancyAssignment`). To reassign,
  first unassign.
- **6.8.5** Assignment of an interviewer to a vacancy is allowed only if the
  interviewer's `employer_id` matches the vacancy's `employer_id`.

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
| `InterviewerAssigned` | An interviewer is linked to a vacancy. |

- **7.2** Every published event contains `event_id`, `event_type`,
  `event_version`, `aggregate_id`, `timestamp`, `correlation_id` and
  event-specific `data`. Compatibility rules are defined in
  [ADR‑012](../../adr/adr-012-event-versioning.md); published event schemas
  belong in [AsyncAPI](../../asyncapi/events.yaml).
- **7.3** `event_id` is a unique uuid of the specific event instance
  (auto-generated on creation) and never equals `aggregate_id`, which only
  identifies the source aggregate and is shared by all events of that
  aggregate. Idempotent application of `CatalogueChangeRequested` commands (see
  11.2) must not rely on `event_id` matching the target aggregate id.
- **7.4** `ExternalPortalUnreachable`, `PortalStructureChanged` and parser-run
  lifecycle events are owned and published by `Parsing&AIConnector`; they are
  intentionally not domain events of this context.

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
  `logo_url` (string, nullable), `created_at` (timestamp), `updated_at`
  (timestamp), `version` (integer, default 1).
- **8.3.2 Behavior:** `addVacancy()`, `removeVacancy()` (only if vacancy is
  closed), `addInterviewer()`, `removeInterviewer()`.

### 8.4 Vacancy (part of Employer but a separate root for search)

- **8.4.1 Fields:** `id` (UUID), `employer_id` (UUID), `title` (string),
  `description` (text, nullable), `min_salary` (integer, USD, default 0),
  `max_salary` (integer, USD, nullable), `status` (enum: open/closed),
  `country` (string, nullable), `city` (string, nullable), `created_at`
  (timestamp), `updated_at` (timestamp), `posted_at` (timestamp),
  `employment_type` (enum: part-time/contract/internship/full-time/volunteer),
  `workplace` (enum: remote/on-site/hybrid), `version` (integer, default 1),
  `internal_url` (string, nullable), `external_urls` (`list<string>`),
  `closed_at` (timestamp, nullable).
- **8.4.2 Relationships:** has many `Requirement` via many-to-many table
  `vacancy_requirements`; has many `Job` via `VacancyJobAssignment`
  (many-to-many).
- **8.4.3 Behavior:** `closeVacancy()`, `assignToJob()`, `unassignFromJob()`,
  `addRequirement()`, `removeRequirement()`.
- **8.4.4 Note:** Salary is stored in USD only. Multi-currency support is
  planned for a future version.

### 8.5 Interviewer

- **8.5.1 Fields:** `id` (UUID), `portal_id` (UUID, references `Portal`),
  `employer_id` (UUID), `full_name` (string), `position` (string, nullable),
  `profile_urls` (JSON, nullable — e.g., `{"Linkedin": "...", "DOU": "..."}`),
  `created_at` (timestamp), `updated_at` (timestamp), `version` (integer,
  default 1), `is_active` (boolean, default true), `deleted_at` (timestamp,
  nullable).
- **8.5.2 Behavior:** `assignToVacancy()`, `unassignFromVacancy()` (the
  aggregate does not record events itself).
- **8.5.3** `InterviewerAssignedEvent` is published by the assign-interviewer
  use case (application layer) after `assignToVacancy()` succeeds (see 7).

### 8.6 Portal (external portal lookup)

- **8.6.1** This context owns a `Portal` reference/lookup entity that
  represents the external job portals the catalogue aggregates originate from.
- **8.6.2 Type:** reference entity (shared lookup, managed as a reference —
  like `Requirement`); not a behavioural root aggregate.
- **8.6.3 Fields:** `id` (UUID), `code` (string, unique — the `source_key`
  value such as `linkedin`, `djinni`), `name` (string), `base_url` (string,
  nullable), `created_at` (timestamp), `updated_at` (timestamp).
- **8.6.4 Relationship:** `Employer.portal_id` and `Interviewer.portal_id`
  reference a `Portal` by UUID. A Vacancy's origin is tracked per source via
  `VacancySource.source_key`, not via `portal_id`.
- **8.6.5 Behavior:** `addPortal()`, `updatePortal()`, `deletePortal()` —
  delete is allowed only while no Employer or Interviewer references the
  Portal.
- **8.6.6 Ownership boundary:** this context owns the portal identity and
  reference integrity used by the catalogue. Portal *parsing configuration and
  lifecycle* (schedules, rate limits, parse modes) are owned by
  `Parsing&AIConnector` (see ADR‑007), not by this context.

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
- **8.7.4 InterviewerVacancyAssignment — Fields:** `id` (UUID), `interviewer_id`
  (UUID), `vacancy_id` (UUID), `assigned_at` (timestamp), `unassigned_at`
  (timestamp, nullable), `version` (integer, default 1).
- **8.7.5 VacancySource (source provenance) — Fields:** `id` (UUID),
  `vacancy_id` (UUID), `source_key` (string, e.g., `linkedin`),
  `external_vacancy_id` (string), `external_url` (string), `first_seen_at`
  (timestamp), `last_seen_at` (timestamp), `closed_at` (timestamp, nullable),
  `is_primary` (boolean, default false). **Purpose:** tracks which portals a
  vacancy came from and when; provides provenance for the read API, audit
  history and the parser's local projection.

## 9. Interaction with other contexts

| Context | Relationship | Protocol | Responsibility at this boundary |
| --- | --- | --- | --- |
| Parsing&AIConnector | Upstream, Customer-Supplier | RabbitMQ | Supplies approved catalogue-change commands; owns parsing, normalization and duplicate decisions. |
| ResearcherCrm | Downstream, Publisher-Subscriber | RabbitMQ | Receives committed vacancy, merge and interviewer changes for replies and meetings. |
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
- **11.3** Use `(source_key, external_vacancy_id)` to identify the source
  provenance supplied by the command. It protects source-record integrity; it
  is not a duplicate-resolution algorithm in this context.
