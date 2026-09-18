# YML/YAML files Standards

Standards for editing YML/YAML files in the repository: GitHub Actions
workflows (`.github/workflows/*.yml`), Docker Compose files (`deploy/**/*.yml`),
OpenAPI/AsyncAPI specifications (`docs/**/*.yaml`), and lint configs
(`.yamllint.yaml`, `.coderabbit.yaml`). Formatting follows `.yamllint.yaml`;
correctness the target schema. Section 1 applies to every YML/YAML file;
section 2 adds rules for API specifications.

## 1. All YML/YAML files

- **1.1** Lint with yamllint using `.yamllint.yaml`: no document-start `---`,
  comments start with `#` followed by a space, and `true`/`false` are lowercase
  booleans.
- **1.2** Keep every line within 120 characters counted from the line start
  (`.yamllint.yaml` `line-length.max: 120`); wrap long scalars, comments and
  descriptions instead of exceeding it.
- **1.3** Indent with two spaces, never tabs; lists use `- item` with the dash
  and text separated by one space.
- **1.4** Quote a scalar only when required: it looks like a number/boolean,
  contains `:` or special characters, or the schema demands it (e.g. Compose
  `version: '3.8'`); use single quotes, double quotes only for interpolation
  such as `${HOST:-127.0.0.1}`.
- **1.5** Keys are lowercase; use the casing and key order already present in
  the edited file — do not reformat unrelated blocks.
- **1.6** Keep logical grouping stable (info before content, declarations
  before references); when a file sorts keys alphabetically, keep sorting.
- **1.7** Avoid duplicating large repeated blocks — use YAML anchors
  (`&name`/`*name`/`<<:`) where the consuming tool supports them.
- **1.8** Patch only the affected section of a file; mirror the edited file's
  style instead of rewriting the document.
- **1.9** Never commit secrets, credentials, or absolute paths; reference
  environment variables by name (`${VAR}`, `${VAR:-default}`).
- **1.10** File extension follows the kind: workflows and Compose use `.yml`,
  specs and configs `.yaml`; keep the extension already in use for the file.

## 2. API specifications

OpenAPI and AsyncAPI files live in the docs repository: one OpenAPI file per
service at `docs/api/<service>/openapi.yaml` and the AsyncAPI catalog at
`docs/asyncapi/events.yaml`.

- **2.1** Formatting follows section 1 and `.yamllint.yaml`; correctness is
  given by the OpenAPI 3.0 / AsyncAPI 2.x specification.
- **2.2** The `<service>` name in the path is the canonical name of the
  service described by the spec.
- **2.3** Keep each spec file the single source of truth for its contract;
  never duplicate its content in other files.
- **2.4** A spec change is a contract change: land it in the owning service's
  code before release and never leave spec and code diverged; the spec lives
  here, the code change lands in the service repository.
- **2.5** A breaking contract change updates the spec, the client, and all
  consumers in the same change.
- **2.6** Before altering a shared event schema, check producer–consumer
  compatibility; keep channel and message names consistent with existing
  event definitions instead of introducing near-duplicates.
