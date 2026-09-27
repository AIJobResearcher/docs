# Domain Model for AIJobResearcher

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.8

> **Related documentation:** [Glossary](../glossary.md) |
> [Domain Vision](./domain-vision.md) | [Context Map](../context-map.md) |
> [Architecture Overview](../architecture-overview.md) |
> [Technical Requirements](../technical-requirements.md) |
> [Bounded Contexts](./bounded-contexts/) | [README](../README.md)

The domain model of the system is divided into four bounded contexts. Their
boundaries, responsibilities and relationships (upstream/downstream, protocols,
integration messages, data ownership) are fixed in the
[Context Map](../context-map.md); every context is described in its own file in
[bounded-contexts/](./bounded-contexts/).

## 1. Aggregates and Entities

| Context | Aggregates and entities | Lookups and references |
| --- | --- | --- |
| [Vacancy Management](./bounded-contexts/vacancies-market.md) | Employer (root) → Vacancy (separate aggregate) → Source → Content; Interviewer | Requirement, Job, Portal, Location |
| [Job Search & CRM](./bounded-contexts/researcher-crm.md) | Researcher (root) → Reply, Meet, Message, AIRecommendation | Desired Job (reference to a Job of Vacancy Management) |
| [AI & Parsing](./bounded-contexts/parsing-ai-connector.md) | ParsingTask, AIRecommendationTask; VacancyCandidate (internal entity) | AIModel |
| [Learning Management](./bounded-contexts/knowledge-center.md) | LearningTrack (root) → TrackItem, Progress | Skill |

Fields, behaviour and invariants of every aggregate are described in the file of
its bounded context. References between contexts are by id only: there is no
shared kernel.
