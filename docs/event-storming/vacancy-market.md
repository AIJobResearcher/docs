# Event Storming: Vacancy Market

## Commands (triggers)

- **ApplyCatalogueChange** – atomically persist a parser-approved create,
  update, merge or close command.
- **AssignInterviewer** – link an interviewer to a compatible vacancy.

`ApplyCatalogueChange` is an internal integration command. It does not start
parsing, normalize data or select duplicate candidates.

## Domain events

| Event | Published by | Description |
| --- | --- | --- |
| `EmployerImported` | Vacancies Market | A new employer was added to the catalogue. |
| `VacancyImported` | Vacancies Market | A new canonical vacancy was added to the catalogue. |
| `VacancyUpdated` | Vacancies Market | A canonical vacancy changed or was reopened. |
| `VacancyMerged` | Vacancies Market | Parser-selected duplicates were merged into a canonical vacancy. |
| `VacancyClosed` | Vacancies Market | A canonical vacancy was closed after source data confirmed it. |
| `InterviewerAssigned` | Vacancies Market | An interviewer was linked to a vacancy. |

Parser status events, including `ExternalPortalUnreachable` and `ParsingFailed`,
are published by `Parsing&AIConnector`, not by this context.

## Aggregates

- `Employer` – root
- `Vacancy` – separate root aggregate for catalogue and search
- `Job` – root aggregate for the job catalogue
- `Requirement` – shared reference entity
- `Interviewer` – entity belonging to an employer
- `VacancySource` – source provenance for parser projections and audit

## Business rules (invariants)

- A vacancy cannot exist without an employer.
- A public API cannot manually create or update a vacancy; only a valid
  `CatalogueChangeRequested` command can change the catalogue.
- Duplicate resolution, source closure policy and merge selection are owned by
  `Parsing&AIConnector`; this context applies the approved result only.
- When a vacancy changes, a new aggregate version preserves its history.
- An interviewer can be assigned only to a vacancy of the same employer.
