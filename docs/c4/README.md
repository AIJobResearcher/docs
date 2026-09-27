# C4 Diagrams

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.0

> **Related documentation:** [Glossary](../glossary.md) |
> [Architecture Overview](../architecture-overview.md) |
> [Context Map](../context-map.md) |
> [Bounded Contexts](../domain/bounded-contexts/) | [README](../README.md)

PlantUML sources using C4-PlantUML; level 1–2 describe the system, level 3 has
one file per service.

| Level | File | Content |
| --- | --- | --- |
| 1. System context | [context.puml](./context.puml) | Actor, the system and external systems |
| 2. Containers | [containers.puml](./containers.puml) | Services, databases, broker, search and vector stores |
| 3. Components | [components-vacancies-market.puml](./components-vacancies-market.puml) | Vacancy Management layers and aggregates |
| 3. Components | [components-researcher-crm.puml](./components-researcher-crm.puml) | Job Search & CRM layers and aggregates |
| 3. Components | [components-parsing-ai.puml](./components-parsing-ai.puml) | AI & Parsing layers, ACL adapters, RAG pipeline |
| 3. Components | [components-knowledge-center.puml](./components-knowledge-center.puml) | Learning Management layers and aggregates |
| 3. Components | [components-frontend.puml](./components-frontend.puml) | Frontend pages, UI components, API client |

Responsibilities and aggregates of each service – in its bounded context file;
stacks and implementation order –
[Architecture Overview](../architecture-overview.md) §1; context relationships –
[Context Map](../context-map.md).
