# ADR-012: Event Versioning Policy

## Context

Domain events evolve over time: fields are added, types change. Event consumers
(other microservices) may not be ready for sudden changes. Without explicit
versioning, breaking changes will cause consumers to fail.

## Decision

Each event contains an `event_version` field (integer, starting at 1).

- **Non‑breaking changes** (adding an optional field, extending an `enum`) –
  version does not increase.
- **Breaking changes** (removing a mandatory field, changing type, changing
  semantics) – version increases by 1.
- The old event version is published in parallel for at least 30 days
  (`Deprecation Policy`).
- Consumers specify the supported version; if an incompatible version is
  received, the message goes to a dead letter queue.

## Why this decision

- Enables smooth evolution without system downtime.
- Allows different services to upgrade to the new version at different times.
- Does not require complex infrastructure (just a field in JSON).

## Alternatives

- Separate queues/topics for each version – overkill.
- Prefix in `event_type` (e.g., `ReplyCreated_v2`) – less flexible.

## Consequences

- All events must include `event_version`.
- In CI, we must check that breaking changes were not forgotten and the version
  was incremented.
- Old versions require code support for 30 days.

## Related artifacts

- Section "Event Versioning Policy" in `architecture-overview.md`.
- AsyncAPI specification (the `event_version` field).
