#!/usr/bin/env bash
# Install the common command-line tools shared by the general-purpose templates.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

for argument in "$@"; do
  case "$argument" in
    --help)
      printf 'Usage: %s\n\nInstalls common CLI tools, including a Python 3 toolchain, jq, ripgrep, fd, and editors.\n' "$0"
      exit 0
      ;;
    *) die "Unknown argument: $argument" ;;
  esac
done

packages=(
  build-essential
  ca-certificates
  curl
  fd-find
  git
  htop
  jq
  nano
  openssh-client
  python3
  python3-venv
  ripgrep
  shellcheck
  tmux
  tree
  unzip
  vim
  zip
)

ensure_packages "${packages[@]}"

# Debian and Ubuntu install the fd binary as fdfind to avoid a name clash.
if have fdfind && ! have fd; then
  if is_root; then
    ln -sfn "$(command -v fdfind)" /usr/local/bin/fd
  else
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ensure_user_path "$HOME/.local/bin"
  fi
fi

require_cmd git rg jq python3 fd
ok "Common command-line tools are installed."
