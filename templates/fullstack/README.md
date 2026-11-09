# Full-stack template

Ubuntu 24.04 development container for a React/Node.js frontend and a Java backend.

## Included

- Node.js `26.13.0` with npm, npx, and corepack when shipped by Node.
- OpenJDK `21` with `JAVA_HOME=/opt/java/openjdk`.
- OpenCode `2.2.6` installed for the `vscode` user.
- PostgreSQL, Redis, and SQLite client tools.
- Git, OpenSSH, build-essential, Python 3, ripgrep, fd, jq, and common editors.
- VS Code ESLint, Prettier, Java, Gradle, Spring Boot, and EditorConfig extensions.
- Forwarded ports `3000`, `5173`, `8080`, `5432`, and `6379`.

## Use it

```bash
cp -r templates/fullstack/.devcontainer /path/to/project/
```

Reopen the project in a Dev Container or commit `.devcontainer` and create a Codespace.

## Typical commands

Frontend:

```bash
npm install
npm run dev
```

Backend:

```bash
javac -version
java -version
./mvnw --version   # when the project includes the Maven Wrapper
```

Database clients:

```bash
psql --version
redis-cli --version
sqlite3 --version
```

The image includes clients, not database servers. Use a managed database, a separate service container, or a local database process appropriate to the project.

## OpenCode

```bash
opencode
```

Use `/connect` to authenticate a provider and `/models` to choose a model. Installing OpenCode does not include model credits.

## Notes

- Add Maven or Gradle only if the backend needs it; this template stays focused on Node.js and the JDK.
- Use Dev Container service definitions for database containers instead of installing database servers into the development image.
- Do not commit database passwords, provider keys, or connection strings. See [Security](../../docs/security.md).
