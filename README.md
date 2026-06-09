# AIJobResearcher - Deploy & Docs Repository

This repository contains everything needed to deploy and document the
AIJobResearcher platform.

## Contents

- [Documentation](./docs/README.md) – architecture, requirements, ADRs,
  diagrams, scenarios.
- [Deployment](./deploy/) – local documentation deployment helpers.
- [CI/CD](./.github/workflows/) – GitHub Actions pipelines.
- [Scripts](./scripts/) – helper utilities.
- [Load tests](./loadtests/) – k6 scenarios.

## Requirements

Supported operating systems:

- Windows 11
- Ubuntu latest stable
- macOS latest stable

Local documentation deployment uses Docker Compose and requires:

- GNU Make (`make`, or `gmake` on systems where GNU Make is not the default)
- Docker
- Docker Compose plugin (`docker compose`)

Documentation checks additionally use:

- `npx` (bundled with Node.js/npm)
- `yamllint`
- Docker (for Lychee link checker)
- Unix-compatible shell utilities: `find` and `xargs`

Recommended setup by operating system:

| System | Notes |
| --- | --- |
| Windows 11 | Install Docker Desktop, Node.js LTS, Git for Windows, and GNU Make. Run `make` commands from Git Bash or WSL. |
| Ubuntu latest stable | Install `make`, Docker, Docker Compose plugin, Node.js/npm, `yamllint`. |
| macOS latest stable | Install Docker Desktop, Node.js LTS, `yamllint`, and GNU Make. |

## Quick start

Show all available root commands:

    make help

Build the local documentation image and install all dependencies:

    make build

Start documentation locally with Docker Compose:

    make up

By default, docs are served at http://127.0.0.1:8000.

Stop and remove the local documentation container:

    make down

Override host and port:

    make up HOST=0.0.0.0 PORT=8080

## Available Commands

### Setup

| Command | Description |
| --- | --- |
| `make build` | Install all npm dependencies, markdownlint, cucumber-js, pull Lychee Docker image, install yamllint, and build documentation Docker image |

### Local docs deployment

| Command | Description |
| --- | --- |
| `make up` | Start documentation locally at `http://HOST:PORT` (default: localhost:8000) |
| `make down` | Stop and remove the local container |
| `make logs` | View container logs |

### Validation

| Command | Description |
| --- | --- |
| `make test-md` | Lint Markdown files with markdownlint-cli2 |
| `make test-yaml` | Validate YAML files with yamllint |
| `make test-bdd` | Check Gherkin syntax with cucumber-js |
| `make test-links` | Check links in Markdown with Lychee (Docker) |
| `make test` | Run all validations (md + yaml + bdd + links) |

### Direct deployment commands

    make -C deploy/docs/local build   # Build documentation image
    make -C deploy/docs/local up      # Start container
    make -C deploy/docs/local down    # Stop container
    make -C deploy/docs/local logs    # View logs

## CI/CD Pipeline

This repository uses GitHub Actions for continuous integration and deployment.

### Continuous Integration (CI) - .github/workflows/ci.yml

Runs on every push to `main` and pull requests:

1. **Lint Markdown** - Check Markdown files with markdownlint-cli2
2. **Check Links** - Validate links with Lychee Docker image
3. **Validate YAML** - Check all YAML files with yamllint
4. **BDD Tests** - Validate Gherkin feature files syntax with cucumber-js
5. **Generate OpenAPI** (only on push to main) - Create placeholder OpenAPI specs and publish to GitHub Pages

### Continuous Deployment (CD) - .github/workflows/cd.yml

Runs only on push to `main`:

1. **Deploy Infrastructure** - Apply Kubernetes manifests to cluster
2. **Update Documentation** - Deploy `./docs` to GitHub Pages
3. **Notify Status** - Report deployment success or failure

## Local Validation

Before pushing changes, run:

    make test

This runs all the same checks as the CI pipeline:

- Markdown linting
- YAML validation
- BDD syntax checking
- Link checking with Lychee

## Project Structure

    .
    ├── .github/workflows/       # CI/CD pipelines
    │   ├── ci.yml              # Continuous Integration
    │   └── cd.yml              # Continuous Deployment
    ├── deploy/                 # Deployment configurations
    │   ├── k8s/               # Kubernetes manifests
    │   └── docs/              # Documentation deployment helpers
    ├── docs/                  # Documentation source
    ├── scripts/               # Helper scripts
    ├── loadtests/             # k6 load testing scenarios
    ├── Makefile               # Main make commands
    ├── lychee.toml           # Lychee link checker config
    ├── .markdownlint.json    # Markdown linting config
    ├── .yamllint.yaml        # YAML linting config
    └── cucumber.js           # Cucumber BDD config

## Troubleshooting

### Permission denied errors on Linux/macOS

If you encounter `EACCES` errors during `make build`:

    # Fix npm permissions (recommended)
    mkdir ~/.npm-global
    npm config set prefix '~/.npm-global'
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc

    # Or use sudo (not recommended for production)
    sudo npm install -g markdownlint-cli2

### Docker not running

Ensure Docker daemon is running:

    docker ps

### Lychee link checker fails

Some external links may be temporarily unavailable. Run with retries:

    docker run --rm -v $(pwd):/input lycheeverse/lychee:latest \
      --config /input/lychee.toml --retry-wait 2 --max-retries 3 \
      /input/docs /input/*.md

### Still having issues?

Run the validation step-by-step to identify the problem:

    make test-md      # Check only Markdown
    make test-yaml    # Check only YAML files
    make test-bdd     # Check only BDD features
    make test-links   # Check only links

Or run all checks with verbose output:

    make test

## Contributing

1. Run `make test` locally before committing
2. Ensure all checks pass
3. Push to `main` branch or create a pull request
4. CI pipeline will run automatically on pull requests
5. CD will deploy to production after merge to `main`