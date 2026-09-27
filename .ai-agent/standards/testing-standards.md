# Testing Standards

Apply with the project `AGENTS.md` and `md-files-standards.md` (shared rules);
this file adds cross-language testing rules. Framework-specific rules stay in
`php-standards.md`, `laravel-standards.md`, `python-standards.md` and
`react-standards.md`.

## 1. Test levels

- **1.1** Test levels follow the Clean Architecture layers and are written in
  this priority order: Domain → Application → Integration → Acceptance.
- **1.2** Domain level first: business rules, invariants and value objects are
  covered by fast tests with no framework, database or network.
- **1.3** Application level: use cases and commands are tested with mocked
  ports.
- **1.4** Integration level: repositories, broker adapters and external clients
  are tested against real infrastructure (database, message broker) or its
  container.
- **1.5** Acceptance level: end-to-end scenarios through the public interface.

## 2. Workflow

- **2.1** TDD loop: Red → Green → Refactor; a test is written before the
  production code.
- **2.2** Every business rule (invariant) must have at least one test.
- **2.3** A bug fix starts with a test that reproduces the defect.
- **2.4** Tests are never skipped or deleted to make a suite green, and no new
  test framework is introduced (see the stack standards).
