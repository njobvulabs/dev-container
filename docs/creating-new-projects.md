# Creating new projects

There are two common ways to start a project with these templates. Both rely on the Codespaces base image and `postCreateCommand` installation.

## Option 1: Copy a template into an existing project

```bash
cp -r templates/react/.devcontainer /path/to/project/
```

Then open the project in a Dev Container or push it and create a Codespace. This is the simplest option when the project already has a repository and toolchain.

Add the container to version control:

```bash
cd /path/to/project
git add .devcontainer
git commit -m "Add development container"
git push
```

Do not commit generated build output, secrets, or `.env` files.

## Option 2: Start a new repository from this template

1. Create a new repository from `njobvulabs/dev-container` using **Use this template** on GitHub, or clone it locally.
2. Copy the selected template's `.devcontainer` directory to the new project root.
3. Remove the rest of the template repository if the new project should not contain all environments.
4. Update the project README and package metadata.
5. Commit and push the result.
6. Create a Codespace from the new repository.

For a repository whose only purpose is one environment, the resulting layout can be:

```text
my-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── post-create.sh
│   ├── common.sh
│   ├── install-*.sh
│   └── ...
├── src/
└── README.md
```

## What the template installs

The Dev Container uses:

```text
mcr.microsoft.com/devcontainers/base:ubuntu-24.04
```

The base image supplies the `vscode` user, `sudo`, Git, and common utilities. The post-create script adds the selected toolchain:

- `react`: Node.js and OpenCode.
- `kotlin-android`: OpenJDK, Gradle, Android SDK, and OpenCode.
- `fullstack`: Node.js, OpenJDK, and OpenCode.
- `general-linux`: Node.js and OpenCode.

The scripts are copied into each template because a Dev Container only sees its `.devcontainer` directory and the workspace.

## Choose the right template

- Use `react` for frontend-only projects.
- Use `kotlin-android` when the project needs the Android SDK and Gradle.
- Use `fullstack` when one workspace contains a Node.js frontend and a Java backend.
- Use `general-linux` when no language-specific template fits.

You can also start from `general-linux` and edit its `post-create.sh`, or add a new installer script. Keep changes in the project's `.devcontainer` so they are versioned with the project.

## Keep template scripts synchronized

In this repository, template scripts are copied from `scripts/`:

```bash
./scripts/sync-template-assets.sh
```

If you modify a template script directly in a downstream project, that is fine; the sync helper applies only to this repository. In this repository, edit the canonical script and synchronize all templates.

## Recommended project additions

- Add a `README.md` with build and test commands.
- Add a `.gitignore` for the project's language and build tools.
- Add a license.
- Add CI that builds and tests the project.
- Add a Codespaces prebuild if the repository is used frequently.

## Avoid

- Do not copy `.git` from this repository into a new project.
- Do not commit provider keys, database passwords, signing keys, or tokens.
- Do not assume the Android emulator runs inside a cloud container.
- Do not commit files created by the installers in your home directory.
