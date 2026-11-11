# General Linux template

Ubuntu 24.04 development container with a practical command-line toolset and Node.js.

## Included

- Node.js `26.13.0` with npm, npx, and corepack when shipped by Node.
- OpenCode `2.2.6` installed for the `vscode` user.
- Common CLI tools: Git, OpenSSH, build-essential, Python 3, jq, ripgrep, fd, tree, tmux, htop, vim, nano, and ShellCheck.
- VS Code EditorConfig and ShellCheck extensions.
- Forwarded ports `3000`, `8000`, and `8080`.

## Use it

```bash
cp -r templates/general-linux/.devcontainer /path/to/project/
```

Reopen the project in a Dev Container or commit `.devcontainer` and create a Codespace.

## Typical commands

```bash
node --version
npm --version
python3 --version
rg --version
fd --version
opencode
```

## Notes

- This template is intentionally generic. Add language runtimes and tools that your project actually needs.
- The container includes `sudo` for the `vscode` user with passwordless access, matching the default Dev Container user model. Do not add untrusted code to a container that has access to your credentials.
- See [Security](../../docs/security.md) before adding secrets or mounting host directories.
