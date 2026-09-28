# Domain Vision: AIJobResearcher

**Status:** accepted
**Date:** 2026-09-27
**Version:** 1.6

> **Related documentation:** [Glossary](../glossary.md) |
> [Context Map](../context-map.md) | [Roadmap](../roadmap.md) |
> [Domain Model](./domain-model.md) | [README](../README.md)

## 1. Business Goals

- Help a job seeker get their desired job as efficiently as possible and with
  minimal time.
- Automate the full job search lifecycle: from searching vacancies on different
  portals to analysing interview results and creating a long‑term learning plan.
- Provide personalised AI recommendations for vacancies, resume improvement,
  search strategy and interview preparation.

## 2. Core Domain

**Job Search & CRM** – the core of the system, where the main business value is
concentrated. It covers the full path of the job seeker: desired jobs, vacancy
search, replies and their statuses, meets with interviewers, messages and reply
analytics. Responsibilities and user stories:
[Job Search & CRM](./bounded-contexts/researcher-crm.md).

## 3. Supporting Domains

**Vacancy Management**, **AI & Parsing** and **Learning Management** support the
core domain: they supply the vacancy catalogue, AI capabilities and learning
tracks. Boundaries, responsibilities and data ownership:
[Context Map](../context-map.md); aggregates of each context:
[Domain Model](./domain-model.md).

## 4. Competitive Advantages

1. **Aggregation of vacancies from different portals** in a single interface –
   the job seeker does not waste time switching between LinkedIn, Djinni and
   others.
2. **Personalised AI recommendations** based on the job seeker’s profile, reply
   history and specific vacancy requirements.
3. **Long‑term learning plans (tracks)** automatically formed based on
   weaknesses identified from interview analysis and requirements.
4. **Flexibility of AI providers** – ability to use local models for free or
   commercial ones if needed.

## 5. Success Metrics

| Metric | Target value | Measurement method |
| --- | --- | --- |
| Time from first registration to first interview invitation | 30% reduction compared to manual search | From the first reply to the first interview invitation |
| Conversion from replies to invitations | Double | Reply.approved / Reply.created |
| Share of job seekers regularly using AI recommendations | > 60% | Number of AI endpoint requests / active users |
| Completed learning tracks | > 40% of created | LearningTrack.completed / LearningTrack.created |

## 6. Scope and Non-goals

- Single tenant: no B2B employer accounts and no multi-tenancy.
- No monetisation, billing or paid plans.
- One job seeker per account; no recruiter-side workflows.
- Generic capabilities are taken off the shelf, not built: authentication,
  audit, full-text search, AI model providers.
- The core domain (Job Search & CRM) is never outsourced; supporting domains
  may be built later or bought.
