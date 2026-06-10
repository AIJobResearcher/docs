# ADR-015: Using an Anti‑Corruption Layer (ACL) for External Systems

## Context

The platform integrates with external portals (LinkedIn, Djinni), AI providers
(OpenAI, Ollama), and Google Calendar. Their data models, protocols, and change
frequency must not pollute the domain model.

## Decision

For each external system we create an ACL – a component inside the corresponding
service:

- **Parsing&AIConnector** – for portals and AI providers.
- **ResearcherCrm** – for Google Calendar.
- **Authentication module** – for Google OAuth2.

The ACL performs:

- Transformation of external data into internal objects (DTOs).
- Validation and normalisation.
- Mapping of errors to internal exceptions.
- Protocol adaptation.

## Why this decision

- Isolates the domain from external "chaos".
- Allows changing the external provider without affecting the domain.
- Simplifies testing (mocking the ACL).

## Alternatives

- Direct integration without isolation – leads to domain infection.
- Using an external ESB – overkill.

## Consequences

- Need to write and maintain ACL adapters.
- ACL must not contain business logic.
- Every change to an external API requires updating only the ACL.

## Related artifacts

- Section "External Integrations. Anti‑Corruption Layer" in
  `architecture-overview.md`.
- ACL code in the respective services.
