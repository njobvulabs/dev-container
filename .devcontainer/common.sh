#!/usr/bin/env bash
# shellcheck disable=SC1091
# Shared helpers for Cloud Dev Templates installation scripts.
# This file is sourced by other scripts; it is not meant to be executed directly.

set -Eeuo pipefail

# Load the canonical pinned versions. Callers set SCRIPT_DIR before sourcing.
if [[ -n ${SCRIPT_DIR:-} && -f "$SCRIPT_DIR/versions.env" ]]; then
  # shellcheck source=versions.env
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/versions.env"
fi

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_INFO='\033[0;36m'
  C_OK='\033[0;32m'
  C_WARN='\033[0;33m'
  C_ERR='\033[0;31m'
else
  C_RESET=''
  C_INFO=''
  C_OK=''
  C_WARN=''
  C_ERR=''
fi

log() {
  printf '%b[info]%b %s\n' "$C_INFO" "$C_RESET" "$*"
}

ok() {
  printf '%b[ok]%b %s\n' "$C_OK" "$C_RESET" "$*"
}

warn() {
  printf '%b[warn]%b %s\n' "$C_WARN" "$C_RESET" "$*" >&2
}

die() {
  printf '%b[error]%b %s\n' "$C_ERR" "$C_RESET" "$*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  local line_number=${1:-unknown}
  printf '%b[error]%b Command failed at line %s (exit %s)\n' \
    "$C_ERR" "$C_RESET" "$line_number" "$exit_code" >&2
  exit "$exit_code"
}

trap 'on_error $LINENO' ERR

have() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    have "$cmd" || die "Required command not found: $cmd"
  done
}

is_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]]
}

# Resolve the home directory of the Dev Container user (vscode by default).
# Set DEV_USER="" to use the current process's HOME instead.
dev_user_home() {
  local user=${DEV_USER-vscode}
  if [[ -n "$user" ]] && have id && have getent && id "$user" >/dev/null 2>&1; then
    getent passwd "$user" | cut -d: -f6
  fi
}

# Installers run as root while the image is built, but the caches they create
# in the dev user's home must stay writable when the container starts. Only
# touch paths inside that home so a root-run installer cannot reassign, for
# example, a system-wide Gradle home it was pointed at explicitly.
ensure_dev_ownership() {
  local path=$1
  is_root || return 0

  local user=${DEV_USER:-vscode}
  id "$user" >/dev/null 2>&1 || return 0
  [[ -e "$path" ]] || return 0

  local home
  home=$(dev_user_home) || return 0
  [[ "$path" == "$home" || "$path" == "$home/"* ]] || return 0

  chown -R "$user:$(id -gn "$user")" "$path"
}

run_root() {
  if is_root; then
    "$@"
  elif have sudo; then
    sudo -E "$@"
  else
    die "This operation requires root privileges, but sudo is not available."
  fi
}

apt_install() {
  have apt-get || die "apt-get is required but was not found."
  local sudo_prefix=()
  if ! is_root; then
    have sudo || die "sudo is required to install system packages."
    sudo_prefix=(sudo -E)
  fi

  # Refresh package lists once per container. Re-running apt-get update for
  # every installer wastes time during post-create.
  local marker="${TMPDIR:-/tmp}/cloud-dev-templates-apt-update-${EUID:-$(id -u)}"
  if [[ ! -f "$marker" ]]; then
    "${sudo_prefix[@]}" apt-get update
    touch "$marker"
  fi

  "${sudo_prefix[@]}" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "$@"
}

ensure_packages() {
  local missing=()
  local package

  if ! have dpkg; then
    apt_install "$@"
    return
  fi

  for package in "$@"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    apt_install "${missing[@]}"
  fi
}

detect_arch() {
  case "$(uname -m)" in
    x86_64 | amd64) printf 'x64' ;;
    aarch64 | arm64) printf 'arm64' ;;
    *) die "Unsupported architecture: $(uname -m)" ;;
  esac
}

download() {
  local url=$1
  local destination=$2
  local partial="$destination.part"

  require_cmd curl
  rm -f "$partial"
  if ! curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors \
    --connect-timeout 20 -o "$partial" "$url"; then
    rm -f "$partial"
    die "Failed to download $url"
  fi
  mv -f "$partial" "$destination"
}

sha256_verify() {
  local file=$1
  local expected=$2
  local actual

  require_cmd sha256sum
  actual=$(sha256sum "$file" | cut -d' ' -f1)
  if [[ "$actual" != "$expected" ]]; then
    die "Checksum mismatch for $file: expected $expected, got $actual"
  fi
}

add_path_line() {
  local file=$1
  local line=$2

  mkdir -p "$(dirname "$file")"
  touch "$file"
  if ! grep -Fxq "$line" "$file"; then
    {
      printf '\n# Added by cloud-dev-templates\n'
      printf '%s\n' "$line"
    } >>"$file"
  fi
}

ensure_user_path() {
  local directory=$1
  local current_user=${USER:-$(id -un)}

  add_path_line "$HOME/.bashrc" "export PATH=\"$directory:\$PATH\""
  add_path_line "$HOME/.profile" "export PATH=\"$directory:\$PATH\""
  if [[ -f "$HOME/.zshrc" ]]; then
    add_path_line "$HOME/.zshrc" "export PATH=\"$directory:\$PATH\""
  fi

  case ":$PATH:" in
    *":$directory:"*) ;;
    *) export PATH="$directory:$PATH" ;;
  esac

  export USER="$current_user"
  hash -r 2>/dev/null || true
}

version_major() {
  local version=$1
  version=${version#v}
  version=${version%%-*}
  local major=${version%%.*}
  if [[ "$major" == "1" ]]; then
    local rest=${version#*.}
    major=${rest%%.*}
  fi
  printf '%s' "$major"
}

cleanup_dir() {
  local directory=$1
  [[ -n "$directory" && -d "$directory" ]] && rm -rf "$directory"
  return 0
}
