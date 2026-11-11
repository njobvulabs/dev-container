# Cloud Dev Templates

Reusable Dev Container definitions for personal cloud development environments. Each template uses a standard Ubuntu 24.04 Dev Container base image and installs its toolchain through `postCreateCommand`, so opening the repository in GitHub Codespaces is enough to set it up.

No custom Docker image is built by this repository. Codespaces uses `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` and runs the template's post-create script inside the container.

## Available templates

| Template | Toolchain | Typical use |
| --- | --- | --- |
| `react` | Node.js 26.13.0, common CLI tools, OpenCode 2.2.6 | React, Vite, TypeScript, frontend work |
| `kotlin-android` | OpenJDK 21, Gradle 9.6.0, Android SDK, OpenCode | Kotlin and Android app development |
| `fullstack` | Node.js 26.13.0, OpenJDK 21, PostgreSQL/Redis/SQLite clients, common CLI tools, OpenCode | React plus Java backend services |
| `general-linux` | Node.js 26.13.0, common CLI tools, OpenCode | General Linux development and scripting |

The base image provides the `vscode` user (UID/GID 1000) with passwordless `sudo`, matching the default Dev Container and Codespaces user.

## Quick start

### Use a template in a new project

Copy the selected `.devcontainer` directory to the project root:

```bash
cp -r templates/react/.devcontainer /path/to/project/
```

Open the project in VS Code and choose **Dev Containers: Reopen in Container**, or commit `.devcontainer` and create a Codespace from the repository.

### Use this repository directly in Codespaces

This repository has a root `.devcontainer` that installs the `general-linux` profile (Node.js and OpenCode). Open the repository and create a Codespace to use it.

To use a different profile in this repository, replace the root `.devcontainer` directory:

```bash
rm -rf .devcontainer
cp -r templates/react/.devcontainer .
```

Then rebuild the container or create a new Codespace. For a separate project, copy the desired template instead.

## How installation works

Each `devcontainer.json` uses the Dev Containers Ubuntu 24.04 base image and runs:

```json
"postCreateCommand": "bash .devcontainer/post-create.sh react"
```

The profile script calls the canonical installers:

- `react`: common CLI tools, then Node.js, then OpenCode.
- `kotlin-android`: OpenJDK, Gradle, Android SDK, then OpenCode.
- `fullstack`: common CLI tools, Node.js, OpenJDK, database clients, then OpenCode.
- `general-linux`: common CLI tools, then Node.js, then OpenCode.

The scripts are idempotent. Rebuilding a container or rerunning the post-create command skips tools that already match the pinned versions.

## Verify the environment

After the Codespace finishes creating, run:

```bash
node --version
opencode --version
```

For Kotlin/Android:

```bash
java -version
gradle --version
sdkmanager --version
adb version
opencode --version
```

For full-stack:

```bash
node --version
java -version
psql --version
redis-cli --version
sqlite3 --version
opencode --version
```

## OpenCode

OpenCode is installed for the `vscode` user at `/home/vscode/.opencode/bin/opencode`. Start it with:

```bash
opencode
```

Use the TUI to authenticate a provider with `/connect`, then select a model with `/models`. Installing OpenCode does not provide model credits; connect a provider you are entitled to use. The installer is downloaded to a temporary file before it runs; set `OPENCODE_INSTALL_SHA256` to verify it against a hash you trust. See [OpenCode](docs/opencode.md) and [Security](docs/security.md).

## Repository layout

```text
.
├── .devcontainer/           # Default general-linux environment for this repo
├── .github/workflows/       # Repository validation workflow
├── docs/                    # Setup, OpenCode, security, and troubleshooting guides
├── scripts/                 # Canonical installers and repository helpers
├── tests/                   # Helper tests run by CI
└── templates/               # Copyable Dev Container definitions
    ├── react/
    ├── kotlin-android/
    ├── fullstack/
    └── general-linux/
```

### Why scripts are copied into each template

A Dev Container receives only its `.devcontainer` directory and workspace. Each template therefore contains the scripts it needs. The canonical copies live in `scripts/`; run the sync helper after changing them:

```bash
./scripts/sync-template-assets.sh
./scripts/sync-template-assets.sh --check
```

Validation fails if a template copy drifts from the canonical script.

## Validation

```bash
./scripts/validate-repo.sh
./tests/run-tests.sh
```

The validator checks required files, JSON syntax, shell syntax, executable bits, workflow names, template profile names, documented versions, and synchronization. CI additionally runs ShellCheck and Actionlint. `make validate`, `make test`, and `make shellcheck` wrap the same commands.

## Pinned versions

| Component | Version |
| --- | --- |
| Dev Container base | `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` |
| Node.js | `26.13.0` |
| OpenJDK | `21` |
| Gradle | `9.6.0` |
| Android command-line tools | `15859902` |
| Android platform | `android-37.0` |
| Android build-tools | `36.0.0` |
| OpenCode | `2.2.6` |

To update a tool, change the version variable in `scripts/versions.env`, synchronize the templates, update the README tables, and rebuild the container. The Android toolchain requires Gradle 9.6.0 or newer, JDK 17 or newer, and build-tools 36.0.0 for API 37.

## Documentation

- [Getting started](docs/getting-started.md)
- [Creating new projects](docs/creating-new-projects.md)
- [OpenCode](docs/opencode.md)
- [Security](docs/security.md)
- [Troubleshooting](docs/troubleshooting.md)

## License

MIT. See [LICENSE](LICENSE).
