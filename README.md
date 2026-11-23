# Cloud Dev Container

A single, self-contained `.devcontainer` folder for cloud development. Copy it into any project root and GitHub Codespaces or VS Code builds a custom Ubuntu 24.04 image with a ready-to-use toolchain — no other files from this repository are needed.

## Use it in a project

```bash
cp -r /path/to/dev-container/.devcontainer /path/to/project/
```

The folder must land at the project root as `.devcontainer/` (containing `devcontainer.json`). Commit it with the project, then either:

- open the project in VS Code and choose **Dev Containers: Reopen in Container**, or
- push it and create a Codespace from the repository.

The first creation builds the custom image and can take several minutes. Later starts reuse it.

## What is in the folder

```text
.devcontainer/
├── devcontainer.json       # build settings, ports, extensions, user
├── Dockerfile              # builds the custom image
├── post-create.sh          # runs the profile installers
├── common.sh               # shared helpers
├── versions.env            # pinned tool versions
├── install-common-tools.sh
├── install-node.sh
└── install-opencode.sh
```

`devcontainer.json` uses `build` rather than `image`:

```json
"build": { "dockerfile": "Dockerfile", "context": "." }
```

The Dockerfile copies the installers into the image and runs the `general-linux` profile at build time. The scripts in this folder are the canonical copies; there is no separate `scripts/` directory.

## Installed tools

| Component | Version |
| --- | --- |
| Dev Container base | `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` |
| Node.js | `26.13.0` |
| OpenCode | `2.2.6` |
| Common CLI tools | Git, ripgrep, fd, jq, Python 3, ShellCheck, tmux, tree, vim, and more |

The `vscode` user (UID/GID 1000) has passwordless `sudo`. Ports `3000`, `8000`, and `8080` are forwarded.

## Verify the environment

```bash
node --version
jq --version
opencode --version
```

## OpenCode

OpenCode is installed at `/home/vscode/.opencode/bin/opencode`. Start it with:

```bash
opencode
```

Use `/connect` to authenticate a provider and `/models` to select a model. Installing OpenCode does not include model credits. To verify the downloaded installer, set `OPENCODE_INSTALL_SHA256` to a hash you trust before building.

## Customize

- Add tools: edit the `RUN` instruction in `Dockerfile` or add an installer to the folder.
- Change versions: edit `.devcontainer/versions.env`, then rebuild the container/image.
- Change ports or editor setup: edit `.devcontainer/devcontainer.json`.
- The configuration requests at least 4 CPUs and 8 GB of RAM via `hostRequirements`, so Codespaces selects a suitably sized machine.

Keep secrets out of the container configuration and out of version control.

## License

MIT. See [LICENSE](LICENSE).
