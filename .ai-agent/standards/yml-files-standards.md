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
  given by the target specification.
- **2.2** Use only the newest stable specification version: OpenAPI 3.2.1 and
  AsyncAPI 3.0. PhpStorm reads only 2.0-3.1, so a 3.2 file opens as plain YAML:
  validate it outside the IDE — `make test-openapi`.
- **2.3** Bump only the last digit of `info.version` for the change you make
  (`8.1.0` → `8.1.1`); any other digit changes only on the user's instruction.
- **2.4** The `<service>` name in the path is the canonical name of the
  service described by the spec.
- **2.5** Keep each spec file the single source of truth for its contract;
  never duplicate its content in other files.
- **2.6** A spec change is a contract change: land it in the owning service's
  code before release and never leave spec and code diverged; the spec lives
  here, the code change lands in the service repository.
- **2.7** A breaking contract change updates the spec, the client, and all
  consumers in the same change.
- **2.8** Before altering a shared event schema, check producer–consumer
  compatibility; keep channel and message names consistent with existing
  event definitions instead of introducing near-duplicates.
- **2.9** Routes are RESTful: resource-oriented plural-noun paths, the HTTP
  method carries the action, no verbs or RPC-style names in paths
  (`POST /jobs`, never `/getJobs`).
- **2.10** A sub-resource of a resource is a nested object field in the payload,
  never flattened into the parent (`employer` holding `employer_id` and
  `employer_title`, not those keys at the top level); the sub-resource
  references its parent as `<parent>_id`.
- **2.11** Every resource schema requires exactly `id` (`required: [id]`); all
  other properties are optional and state their nullability.
- **2.12** Every operation declares a unique `operationId` (camelCase, verb plus
  resource: `getVacancyDetails`, `listLocations`) — Redocly
  `operation-operationId`.
- **2.13** Every tag declared in `tags` carries `summary` and `description` —
  Redocly `tag-description`.
- **2.14** Delete every component no operation references — Redocly
  `no-unused-components`.
