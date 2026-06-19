# Event Storming: Vacancy Market

## Commands (triggers)

- **ImportVacancy** – request to import a vacancy (scheduled or manual)
- **UpdateVacancy** – update existing vacancy on re‑parse
- **CloseVacancy** – close vacancy on the portal
- **AssignInterviewer** – link interviewer to vacancy

## Domain events

| Event | Published by | Description |
| --- | --- | --- |
| `VacancyImported` | Parsing&AIConnector | New vacancy imported |
| `VacancyUpdated` | Parsing&AIConnector | Vacancy updated (text, salary, date) |
| `VacancyClosed` | Parsing&AIConnector | Vacancy closed on the portal |
| `InterviewerAssigned` | Vacancies Market | Interviewer linked to vacancy |
| `ExternalPortalUnreachable` | Parsing&AIConnector | Portal unreachable during parsing |

## Aggregates

- `Employer` – root
- `Vacancy` – part of Employer but a separate aggregate for search
- `Interviewer`
- `Portal` (lookup)

## Business rules (invariants)

- An interviewer belongs to exactly one employer.
- A vacancy cannot exist without an employer.
- Vacancies are only imported, not created manually.
- When updated on the portal, a new version of the vacancy is created
  (history).
