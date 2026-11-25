# Product Capabilities

**Status:** accepted
**Date:** 2026-11-25
**Version:** 1.10

> **Related documentation:** [Glossary](./glossary.md) |
> [Domain Vision](./domain/domain-vision.md) | [Roadmap](./roadmap.md) |
> [Context Map](./context-map.md) |
> [Domain Model](./domain/domain-model.md) |
> [Architecture Overview](./architecture-overview.md) | [README](./README.md)

The product capability map of AIJobResearcher: what the service enables a job
seeker to do, independent of implementation. Capabilities are grouped by the
value stream of a job search and mapped to the bounded context that owns each
one. Scope: product capabilities and the data they need; use cases, UI and API
details live in the context and page specifications.

## 1. Purpose and Users

- **1.1** AIJobResearcher is a specialised service that runs a job seeker's
  search end to end: from choosing where to compete to negotiating an offer.
- **1.2** The single user is the job seeker (single tenant); the outcome is the
  desired job with less time, effort and uncertainty.
- **1.3** A capability is a stable ability of the product that produces a user
  outcome; it is not a feature, screen or endpoint.
- **1.4** The value stream orders capabilities by the stage of the search they
  serve, so overlapping abilities are merged instead of repeated.

## 2. Value Stream

| Stage | User goal | Capabilities |
| --- | --- | --- |
| Discover | See the vacancies worth attention | APP-2, APP-5 |
| Position | Know where to compete and how to be visible | MKT-1–3, VIS-1 |
| Apply | Convert attention into replies | APP-1, APP-3, VIS-2–4 |
| Interview | Convert replies into offers | INT-1–3, LRN-1–2, APP-6 |
| Negotiate | Take good conditions | NEG-1–2 |
| Sustain | Keep going and land well | SUS-1–3, LRN-2 |

## 3. Capability Map

| ID | Capability | User outcome | Context | Roadmap |
| --- | --- | --- | --- | --- |
| MKT-1 | Market segments | Effort goes to segments with demand | AI & Parsing (data: Vacancy Management) | 3 |
| MKT-2 | Target-role tracks | Effort concentrated where demand exceeds supply | Job Search & CRM (data: AI & Parsing) | 3 |
| MKT-3 | Salary benchmarks | Real ranges and net models per segment | AI & Parsing (data: Vacancy Management) | 3 |
| VIS-1 | Application documents | CV, letters and facts kept consistent | Job Search & CRM | 3 |
| VIS-2 | Referral network | Warm introductions through former colleagues | Job Search & CRM | 3 |
| VIS-3 | People base | Recruiters and leads tracked as contacts, not companies | Job Search & CRM | 2 |
| VIS-4 | Publishing assistant | Cases, posts and demos prepared for publishing | Job Search & CRM | 4 |
| APP-1 | Application CRM | Every reply, status and follow-up in one place | Job Search & CRM | 2 |
| APP-2 | Vacancy monitoring and scoring | Fresh, relevant vacancies ranked daily | AI & Parsing (data: Job Search & CRM) | 1 |
| APP-3 | Multichannel outreach | One addressee reached through the best channel | Job Search & CRM | 3 |
| APP-4 | Weekly rhythm | Plan, review and metrics without chaos | Job Search & CRM | 3 |
| APP-5 | On-demand vacancy search | Fresh vacancies for the selected Jobs on request | AI & Parsing (data: Job Search & CRM) | 1 |
| APP-6 | Interview scheduling | Invitations, calendar, moves and reminders in one place | Job Search & CRM | 2 |
| INT-1 | Interview forensics | Known weak spots instead of studying everything | Job Search & CRM | 3 |
| INT-2 | Question bank and mock | Practice with answers and different interviewer types | Job Search & CRM | 3 |
| INT-3 | Screening and English | Fast answers to recruiters and forms | Job Search & CRM | 3 |
| NEG-1 | Negotiation scripts | Scenarios and pauses for a better rate | Job Search & CRM | 3 |
| NEG-2 | Offer review | Risks and terms checked before signing | Job Search & CRM | 3 |
| SUS-1 | Runway model | A realistic search horizon and money plan | Job Search & CRM | 3 |
| SUS-2 | Contract and part-time search | Contract and part-time roles surfaced during the search | Job Search & CRM | 3 |
| SUS-3 | First 90 days | A plan for the probation period | Job Search & CRM | 4 |
| LRN-1 | Gap-driven learning | Confirmed gaps closed through a targeted plan | Learning Management | 4 |
| LRN-2 | Interview support | Preparation notes and answers before or after interviews | Learning Management (data: Job Search & CRM) | 4 |

Stages follow [Roadmap](./roadmap.md) §1: stage 1 is the current release,
stages 2–4 are planned.

## 4. Capability Domains

### 4.1 Market Intelligence

- **4.1.1** MKT-1 groups the market into segments with different demand,
  response speed and pay.
- **4.1.2** MKT-2 keeps a living set of two or three target roles and refreshes
  their demand signals, so the user can switch when the market shifts.
- **4.1.3** MKT-3 collects salary ranges and net pay models per segment from
  vacancies and public sources.

### 4.2 Visibility and Positioning

- **4.2.1** VIS-1 keeps role-specific CV versions, letters and a bank of
  verifiable achievements consistent from one source.
- **4.2.2** VIS-2 reactivates former employers and colleagues for warm
  introductions.
- **4.2.3** VIS-3 stores recruiters, leads and former colleagues as contacts
  with history and reasons to talk.
- **4.2.4** VIS-4 helps prepare cases, posts and demos for the user to publish.

### 4.3 Application Pipeline

- **4.3.1** APP-1 tracks companies, replies, statuses and reminders at fixed
  follow-up intervals.
- **4.3.2** APP-2 scans portals daily, scores matches and removes duplicates
  before the user sees them.
- **4.3.3** APP-3 reaches one addressee through several channels with one
  consistent message.
- **4.3.4** APP-4 gives the search a weekly plan, review and metrics.
- **4.3.5** APP-5 runs a user-triggered search: it parses the selected Jobs
  across portals, removes duplicates and ranks the results.
- **4.3.6** APP-6 schedules interviews: invitations, calendar, rescheduling and
  reminders.

### 4.4 Interview Conversion

- **4.4.1** INT-1 analyses interview records and rejections to locate where
  the user actually loses offers.
- **4.4.2** INT-2 keeps a question bank with reference answers and runs mock
  interviews with different interviewer types.
- **4.4.3** INT-3 prepares short answers and written recruiter replies,
  including English.

### 4.5 Negotiation and Decision

- **4.5.1** NEG-1 offers negotiation scenarios, pauses and parallel-offer
  handling.
- **4.5.2** NEG-2 checks probation terms, penalties, IP and payment conditions
  before an offer is accepted.

### 4.6 Sustainability and Growth

- **4.6.1** SUS-1 models how many months the search can last and what closes
  the financial gap.
- **4.6.2** SUS-2 searches contract, part-time and freelance roles during the
  job search.
- **4.6.3** SUS-3 plans the first 90 days of the new job and the career path
  beyond it.

### 4.7 Learning

- **4.7.1** LRN-1 turns confirmed gaps into a targeted plan, from short
  interview repetition to a long-term learning track.
- **4.7.2** LRN-2 supports interview preparation with notes, answers and
  follow-up material from the learning centre.

## 5. Data Requirements

| Data | Needed by | Owner |
| --- | --- | --- |
| Vacancies and sources | APP-2, MKT-1, MKT-3 | Vacancy Management |
| Portals and parsing runs | APP-2 | AI & Parsing |
| Salary ranges and demand trends | MKT-1, MKT-3 | AI & Parsing |
| Job seeker profile and desired jobs | MKT-2, VIS-1, APP-2, APP-5 | Job Search & CRM |
| Replies, messages and statuses | APP-1, APP-3, INT-1 | Job Search & CRM |
| Interview meetings and calendar | APP-6 | Job Search & CRM |
| Interview transcripts and feedback | INT-1–2, LRN-1 | Job Search & CRM |
| Achievements, cases and contacts | VIS-1, VIS-2–4 | Job Search & CRM |
| Skills and learning progress | LRN-1–2 | Learning Management |

## 6. Boundaries

- **6.1 Out of scope:** mass auto-applications, attending a live interview or
  answering for the user, and multi-tenant employer accounts.
- **6.2 Where AI does not help:** a market with no demand for the profile, live
  interview performance and spoken English, reputation and references, and the
  final decision about a job.
- **6.3 Preparation capabilities (INT-2, LRN-2) work before or after an
  interview only:** question banks, mocks and notes; they never prompt during
  a live call.
- **6.4 Every capability keeps one owning context;** a cross-context capability
  names its supplier in the Context column as `(data: …)`.

## 7. Related Documents

- Bounded contexts:
  [Vacancy Management](./domain/bounded-contexts/vacancies-market.md) §1, §5 —
  vacancies, jobs and sources;
  [Job Search & CRM](./domain/bounded-contexts/researcher-crm.md) §3, §5 —
  profile, replies, meetings and AI recommendations;
  [AI & Parsing](./domain/bounded-contexts/parsing-ai-connector.md) §1, §5 —
  parsing and vacancy records;
  [Learning Management](./domain/bounded-contexts/knowledge-center.md) §1, §5 —
  learning tracks and skills.
- Stages: [Roadmap](./roadmap.md) §1; goals:
  [Domain Vision](./domain/domain-vision.md) §1–§5; interactions:
  [Context Map](./context-map.md).
