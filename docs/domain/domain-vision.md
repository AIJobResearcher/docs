<!-- markdownlint-disable MD013 -->

# Domain Vision: AIJobResearcher

## 1. Business Goals

- Help a job seeker get their desired job as efficiently as possible and with
  minimal time.
- Automate the full job search lifecycle: from searching vacancies on different
  portals to analysing interview results and creating a long‑term learning plan.
- Provide personalised AI recommendations for vacancies, resume improvement,
  search strategy and interview preparation.

## 2. Primary Actors

| Actor | Description | Example actions |
| --- | --- | --- |
| Job seeker (Researcher) | User looking for a job | View vacancies, apply, schedule meetings, get AI recommendations, manage learning |
| Administrator | Technical administrator of the platform | Manage portal parsing, configure AI models, monitor, view audit logs |
| External job portals | LinkedIn, Djinni, other sources | Provide data about vacancies, employers, interviewers |
| AI providers | OpenAI API, local Ollama | Generate recommendations, summaries, answers to questions |
| Google Calendar | Job seeker’s calendar | Create interview events |

## 3. Core Domain

**Job Search & CRM** – this is the core of the system, where the main business
value is concentrated.

- Manage job seeker profile
- Create desired jobs (Job)
- Replies to vacancies and their statuses
- Schedule meetings with interviewers (Meet)
- Exchange messages (Message)
- Reply analytics

This domain will be constantly developed and refined. All other domains support
it.

## 4. Supporting Domains

| Domain | Role | Relationship to Core Domain |
| --- | --- | --- |
| Vacancy Market | Import, store, update vacancies, employers, interviewers | Provides data for searching and applying |
| AI & Parsing | Integrate with AI models, parse portals, generate recommendations | Provides intelligent support for the job seeker |
| Knowledge & Learning | Create tracks, progress, development recommendations | Helps the job seeker close skill gaps |

## 5. Generic Domains

| Domain | Technology used | Note |
| --- | --- | --- |
| Authentication and authorisation | OAuth2, JWT (RS256) | SSO via Google, future LinkedIn |
| Audit and logging | RabbitMQ, Append‑only store | Event‑based audit |
| Message processing | RabbitMQ | Event broker |
| Caching | Redis | Hot data, sessions, rate limiting |
| Search | OpenSearch / Elasticsearch | Full‑text search for vacancies, employers, skills |
| Monitoring and tracing | Prometheus, Grafana, Jaeger (OpenTelemetry) | Observability |
| Container orchestration | Kubernetes (EKS/GKE/AKS/on‑prem) | HPA, Blue‑Green deployment |

## 6. Competitive Advantages

1. **Aggregation of vacancies from different portals** in a single interface –
   the job seeker does not waste time switching between LinkedIn, Djinni and
   others.
2. **Personalised AI recommendations** based on the job seeker’s profile, reply
   history and specific vacancy requirements.
3. **Long‑term learning plans (tracks)** automatically formed based on
   weaknesses identified from interview analysis and requirements.
4. **Asynchronous event‑driven architecture** ensuring fault tolerance and
   horizontal scaling up to 50,000 concurrent users.
5. **Flexibility of AI providers** – ability to use local models (Ollama) for
   free or commercial ones (OpenAI) if needed.
6. **Full observability**: tracing, structured logs, metrics and SLO alerts.
7. **Documentation as Code** – live OpenAPI/AsyncAPI specifications, Gherkin
   scenarios, ADRs.

## 7. Success Metrics

### Business metrics (Customer Success)

| Metric | Target value | Measurement method |
| --- | --- | --- |
| Time from first registration to first interview invitation | 30% reduction compared to manual search | Analyse ReplyCreated and MeetScheduled events |
| Conversion from replies to invitations | Double | Reply.approved / Reply.created |
| Share of job seekers regularly using AI recommendations | > 60% | Number of AI endpoint requests / active users |
| Completed learning tracks | > 40% of created | LearningTrack.completed / LearningTrack.created |

### Technical metrics (System Success)

| Metric | Target (SLO) | Note |
| --- | --- | --- |
| Availability of Vacancies, Researcher CRM | 99.9% | (SLA) |
| Availability of AI & Knowledge | 99.5% | |
| Vacancy search latency (p95) | ≤ 300 ms | |
| Meeting creation latency (p95) | ≤ 400 ms | |
| Maximum load | 50,000 concurrent users | |
| Peak RPS | 20,000 | |
| Eventual consistency for Reply | p95 ≤ 2 sec | From publication to display |

## 8. Domain Boundaries and Language (Ubiquitous Language)

Within the project we use Ubiquitous Language, fixed in ADRs and Bounded Context
Canvas. Key terms:

- **Researcher** – job seeker (platform user)
- **Employer** – employer (company)
- **Vacancy** – job vacancy
- **Interviewer** – interviewer (representative of the employer)
- **Job** – desired job (set of criteria)
- **Reply** – application to a vacancy
- **Meet** – meeting / interview
- **LearningTrack** – long‑term learning plan
- **AIRecommendation** – recommendation generated by AI

All development teams use these terms in code, events, APIs and documentation.

## 9. Architecture Alignment

Domain Vision directly influences architectural decisions:

- Core Domain (Job Search & CRM) is implemented on Symfony (PHP) – the most
  mature stack for complex business logic.
- Supporting Domains use technologically optimal stacks: Python (AI/parsing),
  Go (learning), Laravel (vacancy market).
- Generic Domains are at the infrastructure level (RabbitMQ, Redis, OpenSearch,
  K8s).
- Domain boundaries are clearly reflected in microservices and bounded
  contexts.

## 10. Evolution Strategy

- Version 1.0 – MVP: basic functionality without multi‑tenancy, with local AI
  model.
- Version 1.1 – integration with OpenAI, RAG for contextual recommendations.
- Version 1.2 – expand parsing to 5+ portals, improved analytics.
- Version 2.0 – multi‑tenancy for B2B (employer companies), geographic
  distribution.
