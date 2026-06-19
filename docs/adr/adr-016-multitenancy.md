# ADR-016: Logical Data Isolation for Job Seekers (Multi‑Tenancy for B2C)

## Context

The system is cloud‑based and serves only individual job seekers (B2C).
Organisational multi‑tenancy is not required, but data of different users must
be strictly isolated.

## Decision

We use **logical isolation via `researcher_id`**:

- In the `ResearcherCrm` and `KnowledgeCenter` tables, each record contains
  `researcher_id`.
- All API endpoints that return personal data check that the `researcher_id` in
  the request matches the JWT claim `researcher_id`.
- RabbitMQ events containing personal data also include the `researcher_id`
  field for filtering.
- Vacancies (the `Vacancies Market` service) are public, the `researcher_id` field is
  absent.

## Why this decision

- Simple implementation (single set of tables, one index).
- No cost for separate databases/schemas.
- Easy to scale.

## Alternatives

- Separate database per user – unrealistic.
- Schema per user – hard to manage.

## Consequences

- Must enforce strict `researcher_id` checks at the application level.
- If horizontal sharding is needed in the future, the key will be
  `researcher_id`.
- Access attempts to other users’ data are logged as suspicious actions.

## Related artifacts

- Section "Multi‑Tenancy (Logical Data Isolation for Job Seekers)" in
  `technical-requirements.md`.
- JWT token contains the claim `researcher_id`.
