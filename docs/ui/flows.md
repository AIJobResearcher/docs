# UI Flows

**Status:** accepted
**Date:** 2026-09-18
**Version:** 1.1

> **Related documentation:** [Glossary](../glossary.md) |
> [UI Pages](./pages.md) |
> [Vacancies Market page](./vacancies-market.md) |
> [ADR-019 Frontend Architecture](../adr/adr-019-frontend-architecture.md)

User flows of the Frontend service, one Mermaid diagram per flow. Per-block
states are defined in the page specifications (for example
[vacancies-market.md](./vacancies-market.md) §5) and are not repeated here.
Audience: frontend engineers, QA and analytics.

## 1. Start And Auto-Selection

- **1.1 Trigger:** opening [Vacancies Market](./vacancies-market.md).
- **1.2 Flow:**

```mermaid
flowchart TD
    Open[Open page] --> Guard{Authenticated?}
    Guard -- no --> Login[Sign-in]
    Guard -- yes --> Jobs[Load desired jobs]
    Jobs -- fail --> Blocked[Blocked error + Retry]
    Jobs -- ok --> List[Load first page]
    List -- empty --> Empty[No vacancies + Clear filters]
    List -- error --> Err[Error + Retry]
    List -- ok --> Select[Auto-select newest vacancy]
    Select --> Details[Show details]
```

## 2. Filtering

- **2.1** A tag click, a click on an active tag and "Clear all" all reload the
  list from the first page.
- **2.2 Flow:**

```mermaid
flowchart TD
    Details[Details shown] --> Tag[Click tag]
    Tag --> Load[Reload list from page 1]
    Load --> Active[Tag highlighted]
    Active --> Unset[Click active tag or Clear all]
    Unset --> Load
```

## 3. Switching The Desired Job

- **3.1** Switching resets filters, pagination and selection, then auto-selects
  the newest vacancy (6.6).
- **3.2 Flow:**

```mermaid
flowchart TD
    Pick[Pick another desired job] --> Reset[Reset filters and selection]
    Reset --> Load[Load page 1 scoped to job_id]
    Load --> Select[Auto-select newest vacancy]
```

## 4. Infinite Scroll

- **4.1 Flow:**

```mermaid
flowchart TD
    Scroll[Scroll to list end] --> More{Next page exists?}
    More -- yes --> Append[Append page]
    Append --> Scroll
    More -- no --> Stop[Stop silently]
```

## 5. Errors And Session

- **5.1** Error copy and the Retry action are defined in 6.5 of the page
  specification.
- **5.2 Flow:**

```mermaid
flowchart TD
    Call[API call] --> Code{Status}
    Code -- 401 --> Refresh{Refresh ok?}
    Refresh -- yes --> Retry[Repeat call]
    Refresh -- no --> Expired[Session expired + Retry]
    Code -- 429 --> Limit[Too many requests + Retry]
    Code -- 5xx/network --> Fail[Load error + Retry]
```

## 6. Related Documents

- [UI Pages](./pages.md)
- [Vacancies Market page](./vacancies-market.md)
- [ADR-019 Frontend Architecture](../adr/adr-019-frontend-architecture.md)
- [Glossary](../glossary.md)
