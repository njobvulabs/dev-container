#!/usr/bin/env bash
# Install a pinned Gradle distribution with SHA-256 verification.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

: "${GRADLE_VERSION:?GRADLE_VERSION is not set; ensure versions.env is present beside this script.}"
GRADLE_DIST_URL=${GRADLE_DIST_URL:-https://services.gradle.org/distributions}
FORCE=${FORCE:-false}

for argument in "$@"; do
  case "$argument" in
    --force) FORCE=true ;;
    --help)
      printf 'Usage: %s [--force]\n\nEnvironment variables:\n  GRADLE_VERSION  Gradle version to install (default: %s)\n' \
        "$0" "$GRADLE_VERSION"
      exit 0
      ;;
    *) die "Unknown argument: $argument" ;;
  esac
done

ensure_packages ca-certificates curl unzip
require_cmd curl sha256sum unzip

# `gradle --version` extracts native libraries and creates lock files under
# GRADLE_USER_HOME. In the image build this script is root while that home
# belongs to the dev user, so probe a throwaway home instead of leaving
# root-owned files the dev user cannot write to later.
temporary_dir=""
probe_home=""
if is_root; then
  probe_home=$(mktemp -d)
fi
trap 'cleanup_dir "$temporary_dir"; cleanup_dir "$probe_home"' EXIT

# Repair any root-owned Gradle cache left by an earlier image build so the dev
# user can create the native-library lock files at runtime.
ensure_dev_ownership "${GRADLE_USER_HOME:-$HOME/.gradle}"

gradle_installed_version() {
  local output
  if [[ -n "$probe_home" ]]; then
    output=$(GRADLE_USER_HOME="$probe_home" gradle --version 2>/dev/null || true)
  else
    output=$(gradle --version 2>/dev/null || true)
  fi
  printf '%s\n' "$output" | sed -n 's/^Gradle //p' | head -n 1
}

if have gradle; then
  installed_version=$(gradle_installed_version)
  if [[ "$installed_version" == "$GRADLE_VERSION" && "$FORCE" != "true" ]]; then
    ok "Gradle $GRADLE_VERSION is already installed."
    exit 0
  fi
  log "Replacing Gradle ${installed_version:-unknown} with $GRADLE_VERSION."
fi

temporary_dir=$(mktemp -d)

archive="gradle-${GRADLE_VERSION}-bin.zip"
log "Downloading Gradle $GRADLE_VERSION."
download "$GRADLE_DIST_URL/$archive" "$temporary_dir/$archive"
download "$GRADLE_DIST_URL/$archive.sha256" "$temporary_dir/$archive.sha256"
expected_checksum=$(cut -d' ' -f1 "$temporary_dir/$archive.sha256")
sha256_verify "$temporary_dir/$archive" "$expected_checksum"

if is_root; then
  install_root=/opt/gradle
  bin_dir=/usr/local/bin
  run_root mkdir -p "$install_root"
else
  install_root="$HOME/.local/opt/gradle"
  bin_dir="$HOME/.local/bin"
  mkdir -p "$install_root" "$bin_dir"
fi

run_dir="$install_root/gradle-$GRADLE_VERSION"
if [[ -d "$run_dir" ]]; then
  run_root rm -rf "$run_dir"
fi

if is_root; then
  run_root unzip -q "$temporary_dir/$archive" -d "$install_root"
  run_root ln -sfn "$run_dir/bin/gradle" "$bin_dir/gradle"
else
  unzip -q "$temporary_dir/$archive" -d "$install_root"
  ln -sfn "$run_dir/bin/gradle" "$bin_dir/gradle"
  ensure_user_path "$bin_dir"
fi

hash -r 2>/dev/null || true
installed_version=$(gradle_installed_version)
[[ "$installed_version" == "$GRADLE_VERSION" ]] || \
  die "Gradle installation verification failed: expected $GRADLE_VERSION, got ${installed_version:-none}"
ok "Gradle $GRADLE_VERSION installed at $run_dir."
