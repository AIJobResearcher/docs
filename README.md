<!-- markdownlint-disable MD013 -->

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

- `npx`
- `yamllint`
- Unix-compatible shell utilities: `find` and `xargs`

`npx` is bundled with Node.js/npm. On Windows, install Node.js LTS and
reopen the terminal if `npx` is not recognized.

Recommended setup by operating system:

| System | Notes |
| --- | --- |
| Windows 11 | Install Docker Desktop, Node.js LTS, Git for Windows, and GNU Make. Run `make` commands from Git Bash or WSL so `find` and `xargs` resolve to Unix-compatible tools. |
| Ubuntu latest stable | Install `make`, Docker, the Docker Compose plugin, Node.js/npm, `yamllint`, and `findutils` from the system package manager. |
| macOS latest stable | Install Docker Desktop, Node.js LTS, `yamllint`, and GNU Make. If Homebrew installs GNU Make as `gmake`, either run the documented `make` targets with `gmake` or add GNU Make to `PATH` as `make`. |

On Windows, Git for Windows does not install GNU Make. If `make --version`
prints `bash: make: command not found`, install GNU Make separately, then
reopen the terminal. If Chocolatey is available:

    choco install make

If Scoop is available:

    scoop install make

If only `winget` is available, do not install `GnuWin32.Make` because it is
GNU Make 3.81 and does not support this repository's Makefiles. Install MSYS2
instead, then use an MSYS2 shell:

    winget install --id MSYS2.MSYS2 -e
    pacman -S --needed make

After reopening the terminal, verify:

    make --version

## Quick start

Show all available root commands:

    make help

Build the local documentation image:

    make build

Start documentation locally with Docker Compose:

    make up

By default, docs are served at <http://127.0.0.1:8000>.

For more details, see the [documentation](./docs/README.md).

## Deployment

The current deployment helper is for serving the documentation site locally
through Docker Compose.

Run it from the repository root:

    make build
    make up

This delegates to `deploy/docs/local/Makefile`, builds the documentation image,
and serves the `docs` directory from a container.

Stop and remove the local documentation container:

    make down

You can override host and port:

    make up HOST=0.0.0.0 PORT=8080

The same command can be run directly from the local deployment directory:

    make -C deploy/docs/local build
    make -C deploy/docs/local up
    make -C deploy/docs/local down

## Commands

- `make help` - print available root `make` targets.
- `make lint` - run all documentation checks.
- `make lint-md` - lint Markdown files with `markdownlint-cli2`.
- `make lint-links` - check links in Markdown files with
  `markdown-link-check`.
- `make lint-yaml` - validate YAML files with `yamllint`.
- `make bdd` - dry-run Gherkin feature files with Cucumber.
- `make build` - build the local documentation Docker image.
- `make up` - start docs locally at `http://HOST:PORT` with Docker Compose.
- `make down` - stop and remove the local container.

### Local docs deployment commands

- `make -C deploy/docs/local help` - print available local docs deployment
  targets.
- `make -C deploy/docs/local build` - build the local documentation Docker image.
- `make -C deploy/docs/local up` - start the local documentation container.
- `make -C deploy/docs/local down` - stop and remove the local documentation
  container.
