#!/usr/bin/env bash
# Install OpenCode idempotently without overwriting an existing working install.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

OPENCODE_VERSION=${OPENCODE_VERSION:-2.2.6}
OPENCODE_INSTALL_URL=${OPENCODE_INSTALL_URL:-https://opencode.ai/v2/install}
OPENCODE_INSTALL_DIR=${OPENCODE_INSTALL_DIR:-$HOME/.opencode/bin}
FORCE=${FORCE:-false}

for argument in "$@"; do
  case "$argument" in
    --force) FORCE=true ;;
    --help)
      printf 'Usage: %s [--force]\n\nEnvironment variables:\n  OPENCODE_VERSION  Version to install (default: %s)\n' \
        "$0" "$OPENCODE_VERSION"
      exit 0
      ;;
    *) die "Unknown argument: $argument" ;;
  esac
done

find_opencode() {
  if [[ -x "$OPENCODE_INSTALL_DIR/opencode" ]]; then
    printf '%s' "$OPENCODE_INSTALL_DIR/opencode"
  elif have opencode; then
    command -v opencode
  fi
}

installed_binary=$(find_opencode || true)
if [[ -n "$installed_binary" ]]; then
  installed_version=$("$installed_binary" --version 2>/dev/null | tail -n 1 | sed -E 's/^.*[[:space:]]//; s/^v//' || true)
  if [[ "$FORCE" != "true" && "$OPENCODE_VERSION" != "latest" && "$installed_version" == "$OPENCODE_VERSION" ]]; then
    ensure_user_path "$(dirname "$installed_binary")"
    ok "OpenCode $installed_version is already installed."
    exit 0
  fi
  if [[ "$FORCE" != "true" && "$OPENCODE_VERSION" == "latest" ]]; then
    ensure_user_path "$(dirname "$installed_binary")"
    ok "OpenCode $installed_version is already installed (latest requested)."
    exit 0
  fi
  log "Installing OpenCode $OPENCODE_VERSION over ${installed_version:-unknown}."
fi

ensure_packages ca-certificates curl
require_cmd curl bash

installer_args=(--no-modify-path)
if [[ "$OPENCODE_VERSION" != "latest" ]]; then
  installer_args+=(--version "$OPENCODE_VERSION")
fi

log "Installing OpenCode $OPENCODE_VERSION."
curl -fsSL "$OPENCODE_INSTALL_URL" | bash -s -- "${installer_args[@]}"

installed_binary=$(find_opencode || true)
[[ -n "$installed_binary" ]] || die "OpenCode installer completed, but the binary was not found."

ensure_user_path "$(dirname "$installed_binary")"

installed_version=$("$installed_binary" --version 2>/dev/null | tail -n 1 | sed -E 's/^.*[[:space:]]//; s/^v//' || true)
if [[ "$OPENCODE_VERSION" != "latest" && "$installed_version" != "$OPENCODE_VERSION" ]]; then
  die "OpenCode verification failed: expected $OPENCODE_VERSION, got ${installed_version:-none}"
fi

ok "OpenCode ${installed_version:-$OPENCODE_VERSION} installed at $installed_binary."
