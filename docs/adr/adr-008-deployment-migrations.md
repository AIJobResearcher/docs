# ADR-008: Deployment and Migrations Strategy

## Context

Service updates must happen without downtime (zero‑downtime). Database schema
migrations must not block requests. We need the ability to quickly roll back in
case of problems.

## Decision

- **Feature flags:** new features are hidden behind flags (environment variables
  or an Unleash server in the future).
- **Deployment:** Blue‑Green for stateless services (two environments, traffic
  switching via a router). Canary releases are planned after introducing a
  Service Mesh (Istio).
- **Database migrations:** Expand‑Contract principle:

  - Changes that delete columns/tables go in a separate release.
  - Service code reads and writes both structures during the transition period.
  - For table rebuilds (changing column type), we use `gh-ost` or
    `pt-online-schema-change`.

- **CI:** check migrations for dangerous operations, test backward compatibility
  (old code version on the updated DB).

## Why this decision

- Blue‑Green gives instant rollback (traffic switching).
- Expand‑Contract avoids long table locks.
- Feature flags separate code release from feature activation.

## Alternatives

- Rolling update (Kubernetes) – slower rollback, risk of partial incompatibility.
- Locking migrations (plain `ALTER TABLE`) – leads to downtime.

## Consequences

- Requires double resource capacity during deployment (for two environments).
- All migrations are versioned in the `migrations/` directory. Rollback of
  migrations in production is not automatic (only via backup restore or a new
  migration).
- CI includes a check that a migration does not contain `DROP TABLE` without a
  prior `DROP COLUMN` in a previous release.

## Related artifacts

- ADR-005 (RabbitMQ) – not directly affected, but deployment of services accounts
  for queues.
- Section "CI/CD" in `architecture-overview.md`.
- Blue‑Green manifests in `deploy/k8s/`.
