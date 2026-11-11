#!/usr/bin/env bash
# Install PostgreSQL, Redis, and SQLite client tools (no database servers).

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

for argument in "$@"; do
  case "$argument" in
    --help)
      printf 'Usage: %s\n\nInstalls the psql, redis-cli, and sqlite3 clients.\n' "$0"
      exit 0
      ;;
    *) die "Unknown argument: $argument" ;;
  esac
done

ensure_packages postgresql-client redis-tools sqlite3

require_cmd psql redis-cli sqlite3
ok "Database client tools are installed (psql, redis-cli, sqlite3)."
