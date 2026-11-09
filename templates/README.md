# Template guide

Each directory contains a complete `.devcontainer` directory that can be copied into a project or used as the basis of a repository.

| If you need... | Use |
| --- | --- |
| React, Vite, TypeScript, or frontend tooling | [`react`](react/README.md) |
| Kotlin, Gradle, Android SDK, or APK builds | [`kotlin-android`](kotlin-android/README.md) |
| React frontend plus a Java backend | [`fullstack`](fullstack/README.md) |
| A general Linux shell with Node.js and common tools | [`general-linux`](general-linux/README.md) |

## Copying a template

From the repository root:

```bash
cp -r templates/react/.devcontainer /path/to/new-project/
```

Commit the `.devcontainer` directory with the project. Do not copy the template's README unless it is useful to the project.

## Changing templates

The scripts in each template are generated copies of the canonical files in `scripts/`. Edit the canonical file, then synchronize:

```bash
./scripts/sync-template-assets.sh
./scripts/sync-template-assets.sh --check
```

## Customizing without changing the repository

You can edit a copied `.devcontainer` after copying it. Common changes are:

- Removing VS Code extensions.
- Changing forwarded ports.
- Adding project-specific packages to `post-create.sh` or a new installer.
- Changing the base image or adding Dev Container features.

Keep secrets out of the installer scripts and `devcontainer.json`. See [Security](../docs/security.md).
