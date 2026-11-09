# Troubleshooting

## Codespace setup fails

Open the Codespace creation log from GitHub. The post-create command runs as `vscode` and prints each installer step.

Run the same command manually to see the error:

```bash
bash -x .devcontainer/post-create.sh react
```

Use the matching profile: `react`, `kotlin-android`, `fullstack`, or `general-linux`.

Common causes:

- A network or proxy blocks `nodejs.org`, `services.gradle.org`, `dl.google.com`, or `opencode.ai`.
- The repository root does not contain the `.devcontainer` directory.
- Only `devcontainer.json` was copied, without the installer scripts.
- The Codespace ran out of disk during the Android SDK download.

## Downloads fail or checksums do not match

The Node.js, Gradle, and Android installers verify downloads. A proxy, mirror, or truncated download can cause a checksum failure.

- Check outbound network access.
- Retry the setup; temporary network failures are common.
- Do not bypass checksum verification.
- If you intentionally change an Android tools version, update the pinned SHA-256 in `install-android-sdk.sh`.

## `node`, `gradle`, or `opencode` is not found

The installers add user-level tools to:

```text
/home/vscode/.local/bin
/home/vscode/.opencode/bin
/home/vscode/android-sdk/...
```

The template sets `remoteEnv.PATH` so new terminals see them. If a command is still missing:

```bash
ls -l /home/vscode/.local/bin
ls -l /home/vscode/.opencode/bin
echo "$PATH"
```

Open a new terminal after setup. To rerun installation:

```bash
bash .devcontainer/post-create.sh <profile>
```

## Wrong Node.js version

Node.js is installed at `$HOME/.local/lib/nodejs` and linked into `$HOME/.local/bin`. If the base image already has Node.js, the user-level version must come first in `PATH`.

Check:

```bash
which node
node --version
```

Expected: `26.13.0`. If the system Node.js is selected, open a new terminal or verify that `/home/vscode/.local/bin` appears before the system path.

## OpenCode authentication or model problems

Run:

```bash
opencode
```

Use `/connect` to authenticate and `/models` to select a provider model. If no models appear, complete provider authentication and check outbound network access. Installing OpenCode does not include model credits.

If `postCreateCommand` reruns the installer every time, verify that the installed version matches `OPENCODE_VERSION`:

```bash
/home/vscode/.opencode/bin/opencode --version
```

## Android SDK or license errors

Check the SDK:

```bash
echo "$ANDROID_HOME"
sdkmanager --list_installed
adb version
```

If licenses are missing, rerun the profile setup:

```bash
bash .devcontainer/post-create.sh kotlin-android
```

If you change the platform or build-tools version, update the variables in `install-android-sdk.sh` and rerun setup. Verify the versions exist for the SDK channel.

## Android Gradle build fails

- Use the project's Gradle wrapper when it exists.
- Check that the Android Gradle Plugin version supports the installed Gradle, JDK, and build-tools.
- This template uses JDK 21, Gradle 9.6.0, build-tools 36.0.0, and Android API 37.
- Use a larger Codespaces machine type if the build is killed for memory.
- Check disk space with `df -h`.

The template does not include Android Studio or a graphical emulator. Build APKs with Gradle and test on a device, locally, or in CI.

## Codespaces runs out of disk

The Android SDK is large. Check disk usage:

```bash
df -h
du -sh "$HOME/android-sdk" "$HOME/.gradle" 2>/dev/null
```

Use a larger machine type for Android builds. Remove unused build caches and old Gradle distributions.

## `postCreateCommand` fails immediately

Check the path and shell:

```bash
ls -l .devcontainer/post-create.sh
bash -x .devcontainer/post-create.sh general-linux
```

The command is relative to the workspace folder. Ensure all scripts in `.devcontainer` were copied and committed.

## ShellCheck or Actionlint failures in CI

Run the repository validation locally:

```bash
./scripts/validate-repo.sh
```

Run ShellCheck if it is installed:

```bash
shellcheck scripts/*.sh templates/*/.devcontainer/*.sh
```

Actionlint errors usually indicate a workflow syntax issue; validate the YAML and expression syntax.

## Rebuild from scratch

In VS Code or GitHub Codespaces, choose **Rebuild Container**. If the setup is still stale, delete the Codespace and create a new one.
