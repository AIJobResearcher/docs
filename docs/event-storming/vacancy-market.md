# Event Storming: Vacancy Market

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
