# Glossary (Ubiquitous Language)

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.0

Domain terms of the AIJobResearcher project, used in code, API and
documentation. Technical and infrastructure terms live in their owner documents
(ADR, Technical Requirements, Architecture Overview, AI & RAG Pipeline).

| Term | Description |
| --- | --- |
| **ACL (Anti-Corruption Layer)** | Pattern that protects a context from external systems: converts external data and errors into internal objects (portals, AI providers, calendars). |
| **Aggregate** | Cluster of entities and value objects changed only through its root; the unit of consistency and transactions. |
| **Aggregate Version** | `version` field of a root aggregate, increased on every update; used for optimistic locking (`expected_version`). |
| **AIModel** | AI model used for generation (endpoint, input/output schemas, default flag). Lookup entity of Parsing&AIConnector. |
| **AIRecommendation** | AI recommendation (text, target type and id). Entity of `Researcher` in ResearcherCrm. |
| **AIRecommendationTask** | Task of generating an AI recommendation. Aggregate in Parsing&AIConnector. |
| **Application Layer** | Clean Architecture layer holding use cases / commands; coordinates domain objects and performs access checks. |
| **Bounded Context** | Explicit boundary of a domain model. The project defines four: Vacancy Management, Job Search & CRM, AI & Parsing, Learning Management. |
| **Clean Architecture** | Layering independent of external frameworks: Presentation → Application → Domain → Infrastructure. |
| **Content** | Text content of a source (description). Entity of `Source`. |
| **CQRS** | Command Query Responsibility Segregation: read and write models are separated. |
| **Data Ownership** | Each service is the single source of truth for its aggregates; other contexts reference them by id only. |
| **Desired Job** | Element of the job seeker's desired-jobs list, referencing a `Job`. Entity of `Researcher`. |
| **Domain Event** | Fact that happened in the domain and is published by its context for subscribers; versioning and idempotency – ADR-012 and ADR-013. |
| **Domain Layer** | Clean Architecture layer holding entities, aggregates, value objects and invariants. |
| **Domain Vision** | Document describing strategic goals, domains, competitive advantages, success metrics and non-goals. |
| **Employer** | Company that owns vacancies and interviewers. Root aggregate in Vacancy Management. |
| **Entity** | Domain object with identity that is not a root aggregate; lives inside an aggregate (`Reply`, `Meet`, `Source`). |
| **Event Storming** | Method for modelling a domain: aggregates, entities and business rules. |
| **Eventual Consistency** | Consistency model between contexts with an allowed delay (p95 ≤ 2 s, p99 ≤ 5 s). |
| **Interviewer** | Representative of an employer. Child entity of `Employer`. |
| **Job** | Occupation in the vacancy catalogue. Reference entity in Vacancy Management; the job seeker's desired-jobs list references it by id. |
| **KnowledgeCenter** | Service of the Learning Management context (Go): learning tracks, progress, development recommendations. |
| **LearningTrack** | Long‑term learning plan (track). Root aggregate in KnowledgeCenter. |
| **Location** | Country, region, city or unification of countries. Reference entity in Vacancy Management. |
| **Meet** | Meeting (interview) between a job seeker and an interviewer. Entity of `Researcher` in ResearcherCrm. |
| **Message** | Message between a job seeker and an interviewer within a meeting. Entity of `Researcher`. |
| **Multi‑tenancy** | Logical data isolation between jobseekers by `researcher_id`; B2C only, separation by organizations is out of scope. |
| **Parsing&AIConnector** | Service of the AI & Parsing context (Python): portal parsing, AI recommendations, RAG. |
| **ParsingTask** | External portal parsing task. Aggregate in Parsing&AIConnector. |
| **Portal** | External job portal (LinkedIn, Djinni). Reference entity of Vacancy Management, referenced by `Source`. |
| **Progress** | Completion state of a track item. Entity of `LearningTrack`. |
| **Reference entity (lookup)** | Entity that serves as a dictionary for other aggregates (`Job`, `Requirement`, `Portal`, `Location`, `Skill`). |
| **Reply** | Job seeker's application to a vacancy. Entity of `Researcher` in ResearcherCrm. |
| **Requirement** | Requirement of a vacancy or job. Reference entity of Vacancy Management. |
| **Researcher** | Job seeker (platform user). Root aggregate in ResearcherCrm. |
| **ResearcherCrm** | Service of the Job Search & CRM context (PHP/Symfony). |
| **Skill** | Lookup entity for matching vacancy requirements with learning progress. |
| **Source** | Provenance of a vacancy: portal, external id and url, title, publication date. Entity of `Vacancy`. |
| **TrackItem** | Learning plan item (course, article, practice). Entity of `LearningTrack`. |
| **Ubiquitous Language** | Single language of the domain, used in code, events, API and documentation. |
| **Vacancies Market** | Service of the Vacancy Management context (PHP/Laravel) that owns the vacancy catalogue. |
| **Vacancy** | Public vacancy of the catalogue; aggregate inside `Employer`. |
| **VacancyCandidate** | Internal entity of Parsing&AIConnector: normalized source record, duplicate candidates and the selected catalogue mutation. |
