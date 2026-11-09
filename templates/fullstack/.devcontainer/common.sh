#!/usr/bin/env bash
# shellcheck disable=SC1091
# Shared helpers for Cloud Dev Templates installation scripts.
# This file is sourced by other scripts; it is not meant to be executed directly.

set -Eeuo pipefail

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

  "${sudo_prefix[@]}" apt-get update
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

retry() {
  local attempts=$1
  shift
  local count=1

  until "$@"; do
    if (( count >= attempts )); then
      die "Command failed after ${attempts} attempts: $*"
    fi
    warn "Attempt ${count}/${attempts} failed; retrying: $*"
    count=$((count + 1))
    sleep $((count * 2))
  done
}

download() {
  local url=$1
  local destination=$2
  require_cmd curl
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 \
    -o "$destination" "$url"
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
