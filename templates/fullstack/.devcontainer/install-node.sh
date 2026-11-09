#!/usr/bin/env bash
# Install a pinned Node.js release with SHA-256 verification.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

NODE_VERSION=${NODE_VERSION:-26.13.0}
NODE_DIST_URL=${NODE_DIST_URL:-https://nodejs.org/dist}
FORCE=${FORCE:-false}

for argument in "$@"; do
  case "$argument" in
    --force) FORCE=true ;;
    --help)
      printf 'Usage: %s [--force]\n\nEnvironment variables:\n  NODE_VERSION  Node.js version to install (default: %s)\n' \
        "$0" "$NODE_VERSION"
      exit 0
      ;;
    *) die "Unknown argument: $argument" ;;
  esac
done

ensure_packages ca-certificates curl tar xz-utils
require_cmd tar curl sha256sum

if have node; then
  installed_version=$(node --version 2>/dev/null | sed 's/^v//')
  if [[ "$installed_version" == "$NODE_VERSION" && "$FORCE" != "true" ]]; then
    ok "Node.js $NODE_VERSION is already installed."
    if have npm; then
      ok "npm $(npm --version) is available."
    fi
    exit 0
  fi
  log "Replacing Node.js ${installed_version:-unknown} with $NODE_VERSION."
fi

arch=$(detect_arch)
tarball="node-v${NODE_VERSION}-linux-${arch}.tar.xz"
temporary_dir=$(mktemp -d)
trap 'cleanup_dir "$temporary_dir"' EXIT

log "Downloading Node.js $NODE_VERSION for $arch."
download "$NODE_DIST_URL/v$NODE_VERSION/$tarball" "$temporary_dir/$tarball"
download "$NODE_DIST_URL/v$NODE_VERSION/SHASUMS256.txt" "$temporary_dir/SHASUMS256.txt"

expected_checksum=$(grep "  $tarball\$" "$temporary_dir/SHASUMS256.txt" | cut -d' ' -f1)
[[ -n "$expected_checksum" ]] || die "Could not find checksum for $tarball."
sha256_verify "$temporary_dir/$tarball" "$expected_checksum"

if is_root; then
  install_root=/usr/local/lib/nodejs
  bin_dir=/usr/local/bin
  run_root mkdir -p "$install_root"
  run_root tar -xJf "$temporary_dir/$tarball" -C "$install_root"
  node_prefix="$install_root/node-v${NODE_VERSION}-linux-${arch}"

  for binary in node npm npx corepack; do
    if [[ -e "$node_prefix/bin/$binary" ]]; then
      run_root ln -sfn "$node_prefix/bin/$binary" "$bin_dir/$binary"
    fi
  done
else
  install_root="$HOME/.local/lib/nodejs"
  bin_dir="$HOME/.local/bin"
  mkdir -p "$install_root" "$bin_dir"
  tar -xJf "$temporary_dir/$tarball" -C "$install_root"
  node_prefix="$install_root/node-v${NODE_VERSION}-linux-${arch}"

  for binary in node npm npx corepack; do
    if [[ -e "$node_prefix/bin/$binary" ]]; then
      ln -sfn "$node_prefix/bin/$binary" "$bin_dir/$binary"
    fi
  done
  ensure_user_path "$bin_dir"
fi

hash -r 2>/dev/null || true
installed_version=$(node --version 2>/dev/null | sed 's/^v//')
[[ "$installed_version" == "$NODE_VERSION" ]] || \
  die "Node.js installation verification failed: expected $NODE_VERSION, got ${installed_version:-none}"
ok "Node.js $NODE_VERSION installed at $node_prefix."

if have npm; then
  ok "npm $(npm --version) is available."
fi
