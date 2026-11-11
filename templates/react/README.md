# React template

Ubuntu 24.04 development container for React, Vite, and TypeScript projects.

## Included

- Node.js `26.13.0` with npm, npx, and corepack when shipped by Node.
- OpenCode `2.2.6` installed for the `vscode` user.
- Common CLI tools: Git, OpenSSH, build-essential, Python 3, ripgrep, fd, jq, tree, tmux, htop, vim, nano, and ShellCheck.
- VS Code ESLint, Prettier, Tailwind CSS IntelliSense, Vitest, and EditorConfig extensions.
- Forwarded ports `3000`, `5173`, and `4173`.

## Use it

Copy `.devcontainer` into the project root:

```bash
cp -r templates/react/.devcontainer /path/to/project/
```

Then reopen the project in a Dev Container or commit `.devcontainer` and create a Codespace.

## Typical commands

```bash
npm install
npm run dev
npm test
npm run build
```

If the project uses pnpm or Yarn, enable it with Corepack when available:

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

## OpenCode

```bash
opencode
```

Authenticate with `/connect` and select a model with `/models`. OpenCode does not include model credits; connect a provider you are entitled to use.

## Notes

- `postCreateCommand` is idempotent and skips tools that already match the pinned versions.
- Adjust `forwardPorts` in `devcontainer.json` if the project uses different ports.
- The template intentionally does not install a browser automation stack. Add Playwright or Cypress dependencies to the project if needed.
