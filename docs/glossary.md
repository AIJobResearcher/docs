<!-- markdownlint-disable MD013 -->

# Glossary (Ubiquitous Language)

Main terms of the AIJobResearcher project. Used in code, events, API and
documentation.

| Term | Description |
| --- | --- |
| **ACL (Anti-Corruption Layer)** | Component that protects the domain model from external systems (portals, AI providers, calendars). Transforms external data and errors into internal objects. |
| **Admin** | User role with rights to manage portal parsing, configure AI models, view audit logs. |
| **AIProvider** | Interface for interacting with AI models (OllamaAIProvider, OpenAIProvider). |
| **AIRecommendation** | Entity in ResearcherCrm that stores a generated AI recommendation (text, type, target object). |
| **Application Layer** | Layer in Clean Architecture containing use cases / commands. Coordinates domain objects. |
| **BDD (Behavior-Driven Development)** | Development approach through executable Gherkin scenarios run in CI. |
| **Bounded Context** | Boundary of a domain model. The project defines contexts: Vacancy Management, Job Search & CRM, AI & Parsing, Learning Management. |
| **Breaking change** | Change in an event that requires increasing `event_version` (removal of a mandatory field, type change, etc.). |
| **Celery** | Background worker for async tasks (parsing, AI requests) in Parsing&AIConnector. |
| **Chunking** | Splitting a document into fragments (chunks) for RAG (500 tokens, overlap 50). |
| **Clean Architecture** | Architectural approach independent of external frameworks; layers: Presentation, Application, Domain, Infrastructure. |
| **Correlation ID** | Unique identifier passed through all services and events for request tracing. |
| **CPU utilization** | Processor usage metric, used for HPA (target 70%). |
| **CQRS** | Command Query Responsibility Segregation – separation of read and write operations. |
| **Data Ownership** | Principle that each microservice is the single source of truth for its aggregates. |
| **Dead Letter Queue (DLQ)** | Queue for RabbitMQ messages that could not be processed after several attempts. |
| **Deploy Key** | SSH key for publishing OpenAPI specifications to the `docs` repository. |
| **Documentation as Code** | Approach where documentation is stored in the repository, versioned, checked in CI. |
| **Domain Layer** | Layer in Clean Architecture containing business entities, aggregates, value objects and invariants. |
| **Domain Vision** | Document describing strategic goals, actors, domains and success metrics. |
| **Embeddings** | Vector representation of text used in RAG to find relevant fragments. |
| **Employer** | Employer (company), owner of vacancies and interviewers. Aggregate in Vacancies service. |
| **Event Storming** | Method for modelling events, commands, aggregates and business rules for a domain. |
| **Eventual Consistency** | Consistency model where a delay of 2‑5 seconds between services is allowed. |
| **ExternalPortalUnreachable** | Event signalling that an external job portal is unreachable. |
| **Feature flag** | Mechanism to enable/disable functionality without deployment. |
| **GDPR** | General Data Protection Regulation – requirements for deletion and export of personal data. |
| **Gherkin** | Language for BDD scenarios (Feature, Scenario, Given/When/Then). |
| **HPA (Horizontal Pod Autoscaler)** | Kubernetes mechanism for automatically scaling the number of replicas. |
| **Idempotency Key** | Unique key sent by the client in the request header to prevent duplication. |
| **Interviewer** | Interviewer – representative of the employer, linked to a vacancy. Aggregate in Vacancies service. |
| **Jaeger** | Distributed tracing system (OpenTelemetry → Jaeger). |
| **Job** | Desired job – a set of criteria created by the job seeker. Aggregate in ResearcherCrm. |
| **JWT (JSON Web Token)** | Token format for authentication and authorisation (RS256, lifetime 15 minutes). |
| **k6** | Load testing tool. |
| **KnowledgeCenter** | Go service that manages long‑term learning plans, tracks, progress. |
| **LearningTrack** | Long‑term learning plan (track). Aggregate in KnowledgeCenter. |
| **Meet** | Meeting (interview) between a job seeker and an interviewer. Aggregate in ResearcherCrm. |
| **Message** | Message between job seeker and interviewer within a meeting or vacancy. |
| **Multi-tenancy** | Data isolation between users (`researcher_id` in each table). For B2C. |
| **NFR (Non-Functional Requirements)** | Non‑functional requirements: performance, availability, security. |
| **OAuth2** | Authorisation protocol used for SSO (Google OAuth2). |
| **Observability** | Observability: tracing, logs, metrics (OpenTelemetry, Prometheus, Loki). |
| **Ollama** | Local server for running AI models (llama3.2). Used in demo mode. |
| **OpenAI** | Commercial AI provider (gpt-3.5-turbo). Optional. |
| **OpenSearch / Elasticsearch** | Search engine for full‑text search of vacancies, employers, skills. |
| **Outbox Pattern** | Pattern for reliable event publication: saving to an `outbox_messages` table in the same transaction. |
| **Parsing&AIConnector** | Python service responsible for portal parsing, AI recommendations and RAG. |
| **ParsingTask** | External portal parsing task. Aggregate in Parsing&AIConnector. |
| **Portal** | External job portal (LinkedIn, Djinni). Lookup table. |
| **PostgreSQL** | Relational database. Used by all services except Frontend. |
| **Processed Events Table** | Table for storing already processed `event_id`s (used for idempotency). |
| **Progress** | Progress of completing a track item. Aggregate in KnowledgeCenter. |
| **Prometheus** | Metrics collection and alerting system. |
| **Qdrant** | Vector database for RAG (self‑hosted). |
| **RabbitMQ** | Message broker for asynchronous communication between services. |
| **RAG (Retrieval-Augmented Generation)** | Technology for augmenting prompts with relevant fragments from a vector DB. |
| **Rate limiting** | Limiting the number of requests (100/min for authenticated). |
| **Reply** | Job seeker’s application to a vacancy. Aggregate in ResearcherCrm. |
| **Researcher** | Job seeker (platform user). Aggregate in ResearcherCrm. |
| **ResearcherCrm** | PHP service (Symfony), central to the job search domain. |
| **RPO (Recovery Point Objective)** | Maximum acceptable data loss (0 for critical services). |
| **RTO (Recovery Time Objective)** | Recovery time after a failure (1 hour for critical services). |
| **Search Architecture** | Component based on OpenSearch/Elasticsearch for full‑text search. |
| **Skill** | Skill (lookup table) for matching vacancy requirements and learning progress. |
| **SLA (Service Level Agreement)** | Promised availability level (99.9% for critical services). |
| **SLO (Service Level Objective)** | Target latency for key operations (e.g., p95 ≤ 300 ms). |
| **SSO (Single Sign-On)** | Single sign‑on via Google OAuth2 (future LinkedIn). |
| **TDD (Test-Driven Development)** | Development through testing: Red → Green → Refactor. |
| **Tenant ID** | Tenant identifier; in the project it matches `researcher_id` for data isolation. |
| **TrackItem** | Learning plan item (course, article, practice). Aggregate in KnowledgeCenter. |
| **Ubiquitous Language** | Common language used in code, events, API and documentation. |
| **Vacancies** | PHP service (Laravel) managing vacancies, employers, interviewers. |
| **Vacancy** | Vacancy – public information, imported from portals. Aggregate in Vacancies. |
| **Vector Database** | Database for storing and searching vector representations (Qdrant). |
| **Version (aggregate)** | Field for optimistic locking. |
| **event_version** | Schema version of an event (integer, increased on breaking changes). |
