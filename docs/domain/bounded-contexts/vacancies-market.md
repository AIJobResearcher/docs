# Bounded Context: Vacancy Management (Vacancies Market Service)

**Status:** accepted
**Date:** 2026-09-30
**Version:** 1.70

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [Context Map](../../context-map.md) |
> [OpenAPI](../../api/vacancies-market/openapi.yaml) |
> [UI Page](../../ui/vacancies-market.md) |
> [AsyncAPI](../../asyncapi/events.yaml) |
> [Technical Requirements](../../technical-requirements.md) |
> [README](../../README.md)
>
> **Related ADRs:** [ADR‑007: External portal parsing
> strategy](../../adr/adr-007-parsing-strategy.md) |
> [ADR‑011: Outbox Pattern](../../adr/adr-011-outbox-pattern.md) |
> [ADR‑013: Idempotency](../../adr/adr-013-idempotency.md) |
> [ADR‑014: OpenSearch](../../adr/adr-014-opensearch.md) |
> [ADR‑021: Context Communication](../../adr/adr-021-context-communication.md)

## 1. Responsibility

- **1.1** Own the canonical, read-optimized catalogue of jobs, vacancies,
  employers, interviewers, requirements and locations.
- **1.2** Provide read access to the catalogue and publish committed changes
  for other contexts and search indexes.
- **1.3** Ingest parsed portal records: normalize them, match duplicates and
  decide the catalogue creates, updates, merges and closures.

## 2. Business processes and context boundary

- **2.1** Expose catalogue data through the read API and keep its search read
  model current.
- **2.2** Apply portal updates: consume the new and changed record events of
  AI & Parsing, match each record against the catalogue and apply the resulting
  mutation to a `Source`, `Employer` or `Interviewer`.

## 3. User stories

- **3.1 View vacancies:** a jobseeker browses current vacancies matching their
  desired jobs, filtering by job, employer, location, salary, workplace,
  employment type, status and posting dates.
- **3.2 Apply portal updates:** the catalogue turns parsed portal records into
  creates, updates, merges and closures of sources, employers and interviewers.

## 4. Business invariants

### 4.1 General

- **4.1.1** An approved update or reopen creates a new aggregate version,
  preserving history.

### 4.2 Vacancy

- **4.2.1** A change request is accepted only if its canonical vacancy data
  contains a title, an employer and a publication date (`Source.posted_at`).
- **4.2.2** Each Vacancy must have at least one source with an `external_url`
  (`Source`).
- **4.2.3** A Vacancy is assigned to one or more Jobs (`assignToJob()`,
  `unassignFromJob()`).
- **4.2.4** On update, a supplied `requirements` key replaces the set (an
  absent key keeps it); a duplicate Requirement inside one command is skipped,
  not rejected.

### 4.3 Salary

- **4.3.1** If `max_salary` is provided, it must be ≥ 0.
- **4.3.2** If `min_salary` is not provided, it defaults to 0.
- **4.3.3** If both `min_salary` and `max_salary` are provided, `max_salary`
  must be ≥ `min_salary`.

### 4.4 Employer

- **4.4.1** If an approved change request includes a previously unknown
  employer, the same transaction creates it.

### 4.5 Interviewer

- **4.5.1** An interviewer is a child entity of exactly one Employer and has no
  `employer_id` of its own.

### 4.6 Job

- **4.6.1** A Job cannot be deleted if it is referenced by any active Vacancy.

### 4.7 Requirement

- **4.7.1** All Requirements live in a shared dictionary; Job and Vacancy
  reference them by ID, not by string value.
- **4.7.2** A Requirement cannot be deleted if it is referenced by any active
  Job or Vacancy.

### 4.8 Portal reference

- **4.8.1** `Source` references a `Portal` of AI & Parsing by id; the portal
  registry and its lifecycle are owned there.

### 4.9 Source

- **4.9.1** A Vacancy cannot have two `Source`s with the same (`external_url`).

### 4.10 Location

- **4.10.1** A Location cannot be deleted while referenced by any `Employer`
  or `Vacancy`.

### 4.11 PortalCandidate

- **4.11.1** A candidate changes the catalogue only through its selected
  `decision`; an undecided candidate never mutates a `Source`, `Employer` or
  `Interviewer`.
- **4.11.2** A record already present in `EntityMapping` for its
  (`portal_id`, `external_id`) resolves to the mapped entity without an AI
  similarity comparison.

## 5. Aggregates and entities

### 5.1 Requirement (reference entity)

- **5.1.1 Fields:** `id` (UUID), `title` (string, unique, case-insensitive),
  `description` (string, nullable), `category` (string, nullable — e.g.,
  "technical", "soft-skill", "language", "education"), `created_at` (timestamp),
  `updated_at` (timestamp).
- **5.1.2 Relationships:** referenced by `Job` and by `Vacancy`
  (many-to-many).
- **5.1.3 Behaviour:** `createRequirement()`, `updateRequirement()`,
  `deleteRequirement()`.

### 5.2 Job (reference entity)

- **5.2.1 Fields:** `id` (UUID), `title` (string), `category` (string),
  `sub_category` (string, nullable), `parent_job_id` (UUID, nullable,
  self-reference), `description` (text, nullable), `created_at` (timestamp),
  `updated_at` (timestamp), `version` (integer, default 1), `deleted_at`
  (timestamp, nullable).
- **5.2.2 Relationships:** has many `Requirement`; is assigned to `Vacancy`
  (many-to-many); self-references a parent `Job`.
- **5.2.3 Behaviour:** `createJob()`, `updateJob()`, `deleteJob()` (soft delete
  — sets `deleted_at`), `assignRequirement()`, `unassignRequirement()`.

### 5.3 Employer (root aggregate)

- **5.3.1 Fields:** `id` (UUID),
  `title` (string), `description` (text, nullable),
  `contacts` (JSON, nullable — list of
  `{"type": "website"|"phone"|"email", "value": "..."}`),
  `logo_url` (string, nullable — URL/path to the employer logo; server path
  now, S3 later), `location_ids` (`list<int>`, references `Location`),
  `created_at` (timestamp), `updated_at` (timestamp), `version` (integer,
  default 1).
- **5.3.2 Relationships:** has many `Vacancy`; has many `Interviewer` as child
  entities; references `Location`.
- **5.3.3 Behaviour:** `addVacancy()`, `removeVacancy()`, `addInterviewer()`,
  `removeInterviewer()`.

### 5.4 Vacancy (aggregate, part of Employer)

- **5.4.1 Fields:** `id` (UUID), `employer_id` (UUID), `title` (string),
  `min_salary` (integer, USD, default 0), `max_salary` (integer, USD,
  nullable), `status` (enum: open/closed), `created_at` (timestamp),
  `updated_at` (timestamp), `employment_types`
  (`list<enum: part-time/contract/internship/full-time/volunteer>`),
  `workplaces` (`list<enum: remote/on-site/hybrid>`),
  `researcher_location_ids` (`list<int>`, references
  `Location`), `version` (integer, default 1), `closed_at` (timestamp,
  nullable).
- **5.4.2 Relationships:** belongs to `Employer`; has many `Source`;
  has many `Requirement` (many-to-many); is assigned to at least one `Job`
  (many-to-many); references `Location`.
- **5.4.3 Behaviour:** `updateVacancy()`, `closeVacancy()`, `reopenVacancy()`,
  `assignToJob()`, `unassignFromJob()`, `assignRequirement()`,
  `unassignRequirement()`, `addSource()`, `updateSource()`, `removeSource()`.

### 5.5 Interviewer (entity, part of Employer)

- **5.5.1 Fields:** `id` (UUID), `full_name` (string), `position` (string,
  nullable), `contacts` (JSON, nullable — list of
  `{"type": "profile_urls"|"phone"|"email", "value": "..."}`),
  `avatar_url` (string, nullable — URL/path to the interviewer photo; server
  path now, S3 later), `created_at` (timestamp), `updated_at` (timestamp),
  `version` (integer, default 1), `deleted_at` (timestamp, nullable).
- **5.5.2 Relationships:** child entity of `Employer`.
- **5.5.3 Behaviour:** `updateInterviewer()`.

### 5.6 Source (entity, part of Vacancy)

- **5.6.1 Fields:** `id` (UUID), `vacancy_id` (UUID), `portal_id` (UUID,
  references `Portal` of AI & Parsing), `external_vacancy_id` (string, null),
  `external_url` (string), `title` (string), `posted_at` (timestamp),
  `created_at` (timestamp), `updated_at` (timestamp).
- **5.6.2 Relationships:** part of `Vacancy`; references a `Portal` of AI &
  Parsing by id; has many `Content`.
- **5.6.3 Behaviour:** `addContent()`, `updateContent()`, `removeContent()`.

### 5.7 Location (reference entity)

- **5.7.1 Fields:** `id` (int), `name` (string(255)), `iso_name` (string(5),
  nullable), `parent_id` (int, nullable — self-reference), `type` (enum:
  country/city/unification-of-countries/region), `created_at` (timestamp),
  `updated_at` (timestamp).
- **5.7.2 Relationships:** self-references a parent `Location`; referenced by
  `Employer` and `Vacancy`.
- **5.7.3 Behaviour:** `createLocation()`, `updateLocation()`,
  `deleteLocation()`.

### 5.8 Content (entity, part of Source)

- **5.8.1 Fields:** `id` (UUID), `source_id` (UUID), `type` (enum: description),
  `value` (text).
- **5.8.2 Relationships:** part of `Source`.
- **5.8.3 Behaviour:** none — content is updated through `Source`.

### 5.9 PortalCandidate (aggregate)

- **5.9.1 Fields:** `id` (UUID), `entity_type`
  (source/employer/interviewer), `portal_id` (UUID), `external_id` (string),
  `raw_payload` (JSON), `normalized_payload` (JSON), `candidate_entity_ids`
  (JSON), `similarity_scores` (JSON), `decision` (create/update/merge/close),
  `decision_rationale` (text), `status`, `created_at`, `decided_at`.
- **5.9.2 Relationships:** consumes the portal records published by AI &
  Parsing; resolves the target through `EntityMapping`; the applied mutation
  touches a `Source`, `Employer` or `Interviewer` — never a `Job`. AI
  similarity for unmatched records is requested from Parsing&AIConnector
  ([AI & RAG Pipeline](../ai-rag-pipeline.md)).
- **5.9.3 Behaviour:** `normalize()`, `findDuplicateCandidates()`,
  `selectMutation()`, `applyMutation()`.

### 5.10 EntityMapping (entity)

- **5.10.1 Fields:** `id` (UUID), `entity_type`
  (source/employer/interviewer), `catalogue_entity_id` (UUID), `portal_id`
  (UUID), `external_id` (string), `external_url` (string), `content_hash`
  (string), `last_seen_at` (timestamp).
- **5.10.2 Relationships:** links one `Source`, `Employer` or `Interviewer` to
  its portal record; referenced by `PortalCandidate` and by the outbound update
  requests of AI & Parsing.
- **5.10.3 Behaviour:** `resolve(portal_id, external_id)` and
  `refresh(external_url, content_hash)`.

## 6. Interaction with other contexts

All inbound and outbound relationships (types, protocols, messages, purposes):
[Context Map](../../context-map.md) §2.
