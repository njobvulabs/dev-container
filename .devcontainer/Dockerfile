FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# This folder is self-contained: the installers are copied in and run while
# the image is built. Paste .devcontainer into any project root and Codespaces
# or VS Code builds the same toolchain without a separate scripts/ directory.
COPY . /tmp/cloud-dev-setup/
RUN chmod +x /tmp/cloud-dev-setup/*.sh

# Pin the tool locations for both the build and the running container.
ENV JAVA_HOME=/opt/java/openjdk \
    ANDROID_HOME=/home/vscode/android-sdk \
    ANDROID_SDK_ROOT=/home/vscode/android-sdk \
    GRADLE_USER_HOME=/home/vscode/.gradle
ENV PATH="/opt/java/openjdk/bin:/home/vscode/.local/bin:/home/vscode/.opencode/bin:/home/vscode/android-sdk/cmdline-tools/latest/bin:/home/vscode/android-sdk/platform-tools:/home/vscode/android-sdk/emulator:${PATH}"

# Change the installer list in post-create.sh to bake different tools into the image.
RUN bash /tmp/cloud-dev-setup/post-create.sh all \
 && node --version \
 && java -version \
 && gradle --version \
 && sdkmanager --version \
 && adb version \
 && jq --version \
 && opencode --version \
 && rm -rf /tmp/cloud-dev-setup \
 && rm -rf /var/lib/apt/lists/*
