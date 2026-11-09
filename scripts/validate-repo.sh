#!/usr/bin/env bash
# Validate repository structure, JSON, shell syntax, executable bits, and synced copies.

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
FAILED=0
ENVIRONMENTS=(react kotlin-android fullstack general-linux)

fail() {
  printf '[error] %s\n' "$*" >&2
  FAILED=1
}

check_file() {
  [[ -f "$ROOT_DIR/$1" ]] || fail "Missing file: $1"
}

check_executable() {
  [[ -x "$ROOT_DIR/$1" ]] || fail "File is not executable: $1"
}

validate_json() {
  local file=$1
  if command -v jq >/dev/null 2>&1; then
    jq empty "$ROOT_DIR/$file" || fail "Invalid JSON: $file"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$ROOT_DIR/$file" >/dev/null || fail "Invalid JSON: $file"
  else
    fail "Neither jq nor python3 is available to validate JSON."
  fi
}

for root_file in README.md LICENSE .gitignore .devcontainer/devcontainer.json; do
  check_file "$root_file"
done
validate_json ".devcontainer/devcontainer.json"

for script in "$ROOT_DIR"/scripts/*.sh; do
  [[ -f "$script" ]] || continue
  check_executable "scripts/$(basename "$script")"
  bash -n "$script" || fail "Shell syntax error: ${script#"$ROOT_DIR"/}"
done

for environment in "${ENVIRONMENTS[@]}"; do
  template_dir="templates/$environment"
  check_file "$template_dir/README.md"
  check_file "$template_dir/.devcontainer/devcontainer.json"
  check_file "$template_dir/.devcontainer/post-create.sh"
  validate_json "$template_dir/.devcontainer/devcontainer.json"

  for script in "$ROOT_DIR/$template_dir"/.devcontainer/*.sh; do
    [[ -f "$script" ]] || continue
    check_executable "${script#"$ROOT_DIR"/}"
    bash -n "$script" || fail "Shell syntax error: ${script#"$ROOT_DIR"/}"
  done
done

for workflow in "$ROOT_DIR"/.github/workflows/*.yml; do
  [[ -f "$workflow" ]] || continue
  grep -Eq '^name:' "$workflow" || fail "Workflow has no name: ${workflow#"$ROOT_DIR"/}"
done

if ! bash "$SCRIPT_DIR/sync-template-assets.sh" --check; then
  fail "Template assets are not synchronized."
fi

if (( FAILED != 0 )); then
  printf '\nValidation failed.\n' >&2
  exit 1
fi

printf '\nValidation passed.\n'
