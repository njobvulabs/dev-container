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

check_version_doc() {
  local file=$1
  local value=$2
  grep -Fq "$value" "$ROOT_DIR/$file" || fail "Version $value is missing from $file"
}

check_doc_versions() {
  local file=$1
  shift
  local value

  check_file "$file"
  for value in "$@"; do
    check_version_doc "$file" "$value"
  done
}

for root_file in README.md LICENSE .gitignore .gitattributes .editorconfig Makefile \
  .devcontainer/devcontainer.json scripts/versions.env tests/run-tests.sh; do
  check_file "$root_file"
done
check_executable "tests/run-tests.sh"
validate_json ".devcontainer/devcontainer.json"

# shellcheck source=versions.env
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/versions.env"

check_doc_versions README.md \
  "$NODE_VERSION" "$JAVA_MAJOR" "$GRADLE_VERSION" \
  "$ANDROID_CMDLINE_TOOLS_VERSION" "$ANDROID_PLATFORM" "$ANDROID_BUILD_TOOLS" \
  "$OPENCODE_VERSION"

check_doc_versions templates/react/README.md "$NODE_VERSION" "$OPENCODE_VERSION"
check_doc_versions templates/general-linux/README.md "$NODE_VERSION" "$OPENCODE_VERSION"
check_doc_versions templates/fullstack/README.md "$NODE_VERSION" "$JAVA_MAJOR" "$OPENCODE_VERSION"
check_doc_versions templates/kotlin-android/README.md \
  "$JAVA_MAJOR" "$GRADLE_VERSION" "$ANDROID_CMDLINE_TOOLS_VERSION" \
  "$ANDROID_PLATFORM" "$ANDROID_BUILD_TOOLS" "$OPENCODE_VERSION"

for script in "$ROOT_DIR"/scripts/*.sh; do
  [[ -f "$script" ]] || continue
  check_executable "scripts/$(basename "$script")"
  bash -n "$script" || fail "Shell syntax error: ${script#"$ROOT_DIR"/}"
done

for environment in "${ENVIRONMENTS[@]}"; do
  template_dir="templates/$environment"
  devcontainer="$template_dir/.devcontainer/devcontainer.json"
  post_create="$template_dir/.devcontainer/post-create.sh"

  check_file "$template_dir/README.md"
  check_file "$devcontainer"
  check_file "$post_create"
  validate_json "$devcontainer"

  configured_profile=""
  if command -v jq >/dev/null 2>&1; then
    configured_profile=$(jq -r '.postCreateCommand // empty' "$ROOT_DIR/$devcontainer" |
      sed -nE 's/.*post-create\.sh[[:space:]]+([A-Za-z0-9_-]+).*/\1/p')
  fi
  if [[ -z "$configured_profile" ]]; then
    configured_profile=$(sed -nE 's/.*post-create\.sh[[:space:]]+([A-Za-z0-9_-]+).*/\1/p' "$ROOT_DIR/$devcontainer")
  fi
  [[ "$configured_profile" == "$environment" ]] ||
    fail "$devcontainer runs profile '${configured_profile:-unknown}', expected '$environment'"

  while IFS= read -r referenced; do
    [[ -n "$referenced" ]] || continue
    check_file "$template_dir/.devcontainer/$referenced"
  done < <(awk -v profile="$environment" '
    $0 ~ "^[[:space:]]*" profile "\\)" { in_block = 1; next }
    in_block && /^[[:space:]]*;;/ { exit }
    in_block { print }
  ' "$ROOT_DIR/$post_create" | grep -oE 'install-[a-z0-9-]+\.sh' | sort -u)

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
