# Getting started

These templates are designed for GitHub Codespaces. They use a standard Ubuntu 24.04 Dev Container base image and install the selected toolchain through `postCreateCommand`. No custom Docker image needs to be built.

## Prerequisites

- A GitHub account with Codespaces access.
- A repository containing a `.devcontainer` directory at its root.
- Outbound network access from the Codespace to GitHub, `nodejs.org`, `services.gradle.org`, `dl.google.com`, and `opencode.ai`.

VS Code with the Dev Containers extension is optional if you want to run the same configuration locally. Local use still requires Docker.

## Choose a template

| Template | Use it for |
| --- | --- |
| `react` | React, Vite, TypeScript, frontend development |
| `kotlin-android` | Kotlin, Gradle, Android command-line builds |
| `fullstack` | Node.js frontend plus Java backend |
| `general-linux` | General Linux tooling |

See [Templates](../templates/README.md) for details.

## Add a template to a project

The `.devcontainer` directory must be at the project root:

```bash
cp -r templates/react/.devcontainer /path/to/project/
```

Commit it with the project:

```bash
cd /path/to/project
git add .devcontainer
git commit -m "Add development container"
git push
```

## Open the Codespace

1. Open the repository on GitHub.
2. Select **Code** and then the **Codespaces** tab.
3. Create a Codespace.

Codespaces reads `.devcontainer/devcontainer.json` from the repository root. This repository's root configuration uses the `general-linux` profile. A project that copied another template uses that template's profile.

The base image starts quickly; the post-create script then installs the pinned toolchain. The first setup can take several minutes, especially for the Kotlin/Android template. Later starts reuse the Codespace and do not reinstall tools that already match the pinned versions.

## How setup runs

Each `devcontainer.json` contains:

```json
"postCreateCommand": "bash .devcontainer/post-create.sh react"
```

The profile script installs the required tools:

| Profile | Installs |
| --- | --- |
| `react` | Node.js and OpenCode |
| `kotlin-android` | OpenJDK, Gradle, Android SDK, and OpenCode |
| `fullstack` | Node.js, OpenJDK, and OpenCode |
| `general-linux` | Node.js and OpenCode |

The installers are idempotent. Re-running the post-create command is safe.

## Verify the environment

React or general Linux:

```bash
node --version
npm --version
opencode --version
```

Kotlin/Android:

```bash
java -version
gradle --version
sdkmanager --version
adb version
opencode --version
```

Full-stack:

```bash
node --version
java -version
psql --version
opencode --version
```

## Start OpenCode

```bash
opencode
```

Use `/connect` to authenticate a provider and `/models` to select a model. OpenCode requires access to a model provider that you are entitled to use. See [OpenCode](opencode.md).

## Rebuild or rerun setup

In VS Code, use **Dev Containers: Rebuild Container** or **Codespaces: Rebuild Container**. To rerun the installers in a running Codespace:

```bash
bash .devcontainer/post-create.sh react
```

For the Kotlin/Android template:

```bash
bash .devcontainer/post-create.sh kotlin-android
```

## Update template scripts

In this repository, edit the canonical files in `scripts/`, then synchronize the copies:

```bash
./scripts/sync-template-assets.sh
./scripts/sync-template-assets.sh --check
```

If you copied a template into another project, edit the scripts in that project's `.devcontainer` directly.

## Next steps

- [Create a new project](creating-new-projects.md)
- [Configure OpenCode](opencode.md)
- [Review security guidance](security.md)
- [Troubleshoot setup problems](troubleshooting.md)
