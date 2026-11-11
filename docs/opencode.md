# OpenCode

OpenCode is included in every template so an interactive coding agent is available after the Codespace finishes setup.

## Installation details

- Version: `2.2.6` by default, set in `scripts/versions.env` as `OPENCODE_VERSION`.
- Location: `/home/vscode/.opencode/bin/opencode`.
- Installer: official script at `https://opencode.ai/v2/install`.
- Template behavior: `postCreateCommand` runs `post-create.sh`, which calls `install-opencode.sh` after installing the template toolchain.

The repository's installer downloads the official installer to a temporary file and only then executes it. Set `OPENCODE_INSTALL_SHA256` to verify the downloaded script before it runs:

```bash
OPENCODE_INSTALL_SHA256=<sha256-of-installer> ./scripts/install-opencode.sh
```

Without that variable the install still works, but the installer script itself is not checksum-verified.

The installer is idempotent. If the pinned version is already present, it verifies the binary and exits without downloading it again.

## Install manually

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

The repository's installer pins a version:

```bash
./scripts/install-opencode.sh
OPENCODE_VERSION=2.2.6 ./scripts/install-opencode.sh
./scripts/install-opencode.sh --force
```

It passes `--no-modify-path` to the upstream installer and updates shell startup files itself, so repeated runs do not add duplicate entries. The downloaded installer is executed as a file rather than piped directly from `curl`.

## Start OpenCode

```bash
opencode
```

The current CLI uses a terminal UI:

1. Run `opencode` in the project directory.
2. Use `/connect` to authenticate a model provider.
3. Use `/models` to choose a model.

Provider authentication and model availability depend on your accounts. Installing OpenCode does not include free or unlimited model credits.

## Configuration

OpenCode can be configured with an `opencode.json` file in a project or user configuration directory. Keep configuration that contains secrets out of version control.

Check the installed CLI help for the exact options supported by your version:

```bash
opencode --help
```

If you use a project configuration file, review it before committing. Provider credentials should be supplied through the provider's normal authentication flow or environment variables, not hard-coded in a repository.

## Credentials

- Do not commit provider API keys.
- Do not copy auth files into the repository.
- Treat a Codespace as having access to any credentials available inside it.
- Revoke credentials immediately if they are exposed.

The root `.gitignore` excludes common local auth and environment files, but ignore rules are not a substitute for careful secret handling.

## Updating OpenCode

In this repository, change `OPENCODE_VERSION` in `scripts/versions.env`, update the README version table, then synchronize the templates:

```bash
./scripts/sync-template-assets.sh
```

After the change, rebuild the Codespace or rerun:

```bash
bash .devcontainer/post-create.sh <profile>
```

You can also update a running container directly:

```bash
OPENCODE_VERSION=<version> ./scripts/install-opencode.sh --force
```

Changes inside a running Codespace do not persist if the Codespace is deleted. Keep the version change in the repository.

## Network and model access

OpenCode needs outbound network access to its installer and to your model provider. Corporate proxies, firewalls, or Codespaces restrictions can block provider endpoints. Configure the proxy or provider according to your environment.

## Troubleshooting

- `opencode: command not found`: check `PATH`, then run `/home/vscode/.opencode/bin/opencode --version`. Open a new terminal if shell startup files changed.
- Installer runs again on every start: ensure the requested version matches the installed version.
- Authentication fails: re-run `/connect` and verify provider access and network connectivity.
- Model list is empty: complete provider authentication first, then use `/models`.
- Unexpected version: run `opencode --version` and compare it with `OPENCODE_VERSION` in `scripts/versions.env`.

## Security

OpenCode can read project files and execute commands through its tools. Do not point it at a directory containing secrets you do not want exposed to the model or its tools. Review the provider's data handling and your organization's policy before using it with sensitive code.
