# Kotlin / Android template

Ubuntu 24.04 development container for Kotlin and Android command-line builds.

## Included

- OpenJDK `21` (headless) with `JAVA_HOME=/opt/java/openjdk`.
- Gradle `9.6.0` at `/opt/gradle/gradle-9.6.0`.
- Android command-line tools `15859902`.
- Android platform `android-37.0`, build-tools `36.0.0`, and platform-tools (including `adb`).
- OpenCode `2.2.6` installed for the `vscode` user.
- Android SDK licenses accepted by the post-create installer.
- VS Code Kotlin, Gradle, and Java extensions.
- VS Code Java runtime configured to use the installed JDK.

## Use it

```bash
cp -r templates/kotlin-android/.devcontainer /path/to/project/
```

Reopen the project in a Dev Container or commit `.devcontainer` and create a Codespace.

## Typical commands

```bash
java -version
gradle --version
sdkmanager --list_installed
adb devices
./gradlew assembleDebug
```

Use the project's Gradle wrapper when one exists. The setup installs a matching Gradle distribution for bootstrapping new projects.

## Android emulator in the cloud

This template targets command-line builds and physical-device/CI workflows. A graphical Android emulator inside a Codespace is not the default supported path because it needs hardware acceleration, a display, and a larger machine.

Options:

- Build and test on a physical device connected over ADB.
- Run the emulator on your local machine and use the project in a local Dev Container.
- Run instrumentation tests in CI or a device farm such as Firebase Test Lab.
- Build an APK in the container and sideload it to a device.

To connect a physical device over TCP/IP:

```bash
adb connect <device-ip>:5555
adb devices
```

Ports `5037` and `5555` are forwarded for convenience, not as a guarantee that remote ADB will work in every network.

## SDK location and licenses

```text
ANDROID_HOME=/home/vscode/android-sdk
ANDROID_SDK_ROOT=/home/vscode/android-sdk
```

Licenses are accepted by `install-android-sdk.sh` during post-create setup. If you change the platform or build-tools version, rebuild the container and review the licenses.

## Notes

- The template requests at least 2 CPUs, 8 GB of memory, and 32 GB of storage via `hostRequirements`; choose a larger machine type if builds are slow.
- The Android SDK download is large; the first Codespace setup takes longer than the other templates.
- The container does not include Android Studio. Use the Android Gradle Plugin and command-line tools.
- Keep signing keys and `keystore.properties` outside the repository. See [Security](../../docs/security.md).
- Add `local.properties` only if the project needs an explicit SDK path; do not commit machine-specific paths.
