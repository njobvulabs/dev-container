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
  neofetch
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

require_cmd git rg jq python3 fd neofetch

# Show the system summary automatically in interactive shells. The guard keeps
# non-interactive shells (scripts, tasks, scp) free of extra output.
neofetch_line='if [[ $- == *i* ]] && command -v neofetch >/dev/null 2>&1; then neofetch || true; fi'
bashrc_files=("$HOME/.bashrc")
target_home=$(dev_user_home)
if [[ -n "$target_home" && "$target_home" != "$HOME" ]]; then
  bashrc_files+=("$target_home/.bashrc")
fi
for bashrc in "${bashrc_files[@]}"; do
  add_path_line "$bashrc" "$neofetch_line"
  ensure_dev_ownership "$bashrc"
done

ok "Common command-line tools are installed; neofetch runs on interactive shell start."
