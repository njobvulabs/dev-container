# Security

These templates prioritize a usable development environment, not a hardened multi-tenant runtime. Treat Codespaces and Dev Containers as development machines with access to your code and credentials.

## Secrets

Never commit:

- Provider API keys, including model-provider credentials used by OpenCode.
- `.env` files with real values.
- Database passwords or connection strings with credentials.
- SSH private keys.
- Android signing keys, `keystore.properties`, or `local.properties` with machine-specific secrets.
- GitHub or cloud provider tokens.

The root `.gitignore` covers common local files, but verify with:

```bash
git status
git diff --cached
```

Use Codespaces secrets, environment variables, or your provider's authentication flow for runtime secrets. Do not put secrets in `devcontainer.json`, `post-create.sh`, or any installer.

## OpenCode and model providers

Installing OpenCode does not grant access to a model. You must connect a provider and comply with its terms. Model providers may receive code, prompts, and tool output. Review the provider's data handling before using it with sensitive repositories.

OpenCode's tool access means it can read files and run commands in the workspace. Use it deliberately, keep credentials out of the workspace, and revoke access if something is exposed.

## Sudo

The `vscode` user has passwordless `sudo`, which matches common Dev Container and Codespaces behavior. Any code running as that user, including project dependencies and build scripts, can gain root inside the container.

Mitigations:

- Do not run untrusted repositories in a Codespace that has credentials you care about.
- Use separate Codespaces for untrusted code.
- Review build scripts before running them.
- Avoid mounting the Docker socket into the container unless you explicitly need Docker access.

## Supply chain

The post-create installers download tools from upstream projects. Where possible, installs are pinned and verified:

- Node.js: version-pinned tarball verified against `SHASUMS256.txt`.
- Gradle: version-pinned distribution verified against the published `.sha256`.
- Android command-line tools: version-pinned archive verified against a pinned SHA-256 checksum.
- OpenCode: pinned version; the official installer is downloaded to a temporary file before execution and can be verified with `OPENCODE_INSTALL_SHA256`.

Ubuntu packages come from the distribution repositories and are not individually checksum-pinned in the installer scripts. Rebuild the Codespace regularly to pick up security updates, and review changes to installers before updating versions.

The OpenCode installer has no default pinned hash because the upstream script changes independently of the version argument. Set `OPENCODE_INSTALL_SHA256` in CI or your environment if your policy requires verifying the script itself; otherwise the installer is still downloaded to disk first and executed from there.

## Base image and updates

The templates use `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`. For reproducible environments, pin the base image by digest in `devcontainer.json` if your policy requires it. Rebuild Codespaces periodically to receive base image and package updates, and re-test the toolchains after updates.

## Network exposure

Templates forward common development ports. Forwarding makes a service reachable from your machine or browser, but it does not make it public by itself. Do not bind development services to untrusted networks without authentication. Review `forwardPorts` and remove ports the project does not need.

## Android specifics

- Keep signing keys outside the repository.
- Do not commit `keystore.properties` or `local.properties`.
- Use CI secrets or a secure signing service for release builds.
- Treat an APK built with development keys as non-production.
- Android SDK licenses are accepted during post-create setup; review the licenses before redistributing tooling or artifacts.

## Reporting issues

If you find a security issue in this template repository, avoid publishing exploit details in a public issue before the maintainers have had a chance to respond.
