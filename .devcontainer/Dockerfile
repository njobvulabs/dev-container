FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# This folder is self-contained: the installers are copied in and run while
# the image is built. Paste .devcontainer into any project root and Codespaces
# or VS Code builds the same toolchain without a separate scripts/ directory.
COPY . /tmp/cloud-dev-setup/
RUN chmod +x /tmp/cloud-dev-setup/*.sh

# Expose user-level tools to every shell in the image, not only to terminals
# that pick up the devcontainer.json remoteEnv setting.
ENV PATH="/home/vscode/.local/bin:/home/vscode/.opencode/bin:${PATH}"

# Change the profile or add installers here to bake different tools into the image.
RUN bash /tmp/cloud-dev-setup/post-create.sh general-linux \
 && node --version \
 && jq --version \
 && opencode --version \
 && rm -rf /tmp/cloud-dev-setup \
 && rm -rf /var/lib/apt/lists/*
