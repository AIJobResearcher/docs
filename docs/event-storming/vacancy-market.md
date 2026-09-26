# Event Storming: Vacancy Market

## Commands (triggers)

- **ApplyCatalogueChange** – atomically persist a parser-approved create,
  update, merge or close command.

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
| `RequirementDeleted` | Vacancies Market | A Requirement was deleted from the shared dictionary. |

Parser status events, including `ExternalPortalUnreachable` and `ParsingFailed`,
are published by `Parsing&AIConnector`, not by this context.

## Event envelope

Every published event carries `event_id`, `event_type`, `event_version`,
`aggregate_id`, `timestamp`, `correlation_id` and an event-specific `data`
object. Schemas live in [AsyncAPI](../asyncapi/events.yaml), the versioning
policy in [ADR‑012](../adr/adr-012-event-versioning.md), and consumers
deduplicate by `event_id`, which never equals `aggregate_id`
([ADR‑013](../adr/adr-013-idempotency.md)).

## Aggregates and entities

- `Employer` – root aggregate
- `Vacancy` – aggregate for catalogue and search, part of `Employer`
- `Job` – reference entity (job catalogue)
- `Requirement` – reference entity (shared dictionary)
- `Portal` – reference entity (external portals)
- `Location` – reference entity (country / region / city)
- `Interviewer` – entity of `Employer`
- `Source` – source provenance, part of `Vacancy`
- `Content` – source content, part of `Source`

## Business rules (invariants)

- A vacancy cannot exist without an employer.
- A public API cannot manually create or update a vacancy; only a valid
  `CatalogueChangeRequested` command can change the catalogue.
- Duplicate resolution, source closure policy and merge selection are owned by
  `Parsing&AIConnector`; this context applies the approved result only.
- When a vacancy changes, a new aggregate version preserves its history.
