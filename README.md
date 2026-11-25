# Cloud Dev Container

A single, self-contained `.devcontainer` folder for cloud development. Copy it into any project root and GitHub Codespaces or VS Code builds a custom Ubuntu 24.04 image with Node.js, OpenJDK, Gradle, the Android SDK, and OpenCode already installed — no other files from this repository are needed.

## Use it in a project

```bash
cp -r /path/to/dev-container/.devcontainer /path/to/project/
```

The folder must land at the project root as `.devcontainer/` (containing `devcontainer.json`). Commit it with the project, then either:

- open the project in VS Code and choose **Dev Containers: Reopen in Container**, or
- push it and create a Codespace from the repository.

The first creation builds the custom image and downloads the Android SDK, so it can take noticeably longer than a plain Node.js container. Later starts reuse it. Pick the 4-core / 16 GB / 32 GB machine type for Android builds.

## What is in the folder

```text
.devcontainer/
├── devcontainer.json       # build settings, ports, extensions, user
├── Dockerfile              # builds the custom image
├── post-create.sh          # runs the "all" profile installers
├── common.sh               # shared helpers
├── versions.env            # pinned tool versions
├── install-common-tools.sh
├── install-node.sh
├── install-java.sh
├── install-gradle.sh
├── install-android-sdk.sh
└── install-opencode.sh
```

`devcontainer.json` uses `build` rather than `image`:

```json
"build": { "dockerfile": "Dockerfile", "context": "." }
```

The Dockerfile copies the installers into the image and runs the `all` profile at build time. The scripts in this folder are the canonical copies; there is no separate `scripts/` directory.

## Installed tools

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
| Common CLI tools | Git, ripgrep, fd, jq, Python 3, ShellCheck, tmux, tree, vim, and more |

`JAVA_HOME` is `/opt/java/openjdk` and `ANDROID_HOME`/`ANDROID_SDK_ROOT` are `/home/vscode/android-sdk`. The `vscode` user (UID/GID 1000) has passwordless `sudo`. Ports `3000`, `8000`, `8080`, `5037`, and `5555` are forwarded. Android Studio and a graphical emulator are not included; this is a command-line build environment.

## Verify the environment

```bash
node --version
java -version
gradle --version
sdkmanager --version
adb version
opencode --version
```

## OpenCode

OpenCode is installed at `/home/vscode/.opencode/bin/opencode`. Start it with:

```bash
opencode
```

Use `/connect` to authenticate a provider and `/models` to select a model. Installing OpenCode does not include model credits. To verify the downloaded installer, set `OPENCODE_INSTALL_SHA256` to a hash you trust before building.

## Customize

- Add or remove tools: edit the installer list in `post-create.sh`, then rebuild the image.
- Change versions: edit `.devcontainer/versions.env`, then rebuild the container/image.
- Change ports or editor setup: edit `.devcontainer/devcontainer.json`.
- The configuration requests at least 4 CPUs, 16 GB of RAM, and 32 GB of storage via `hostRequirements`, so Codespaces selects the 4-core / 16 GB / 32 GB machine type rather than the smaller 2-core / 8 GB / 32 GB option.

Keep secrets out of the container configuration and out of version control.

## License

MIT. See [LICENSE](LICENSE).
