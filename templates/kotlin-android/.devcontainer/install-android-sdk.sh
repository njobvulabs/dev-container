#!/usr/bin/env bash
# Install Android command-line tools and a pinned Android SDK.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

ANDROID_CMDLINE_TOOLS_VERSION=${ANDROID_CMDLINE_TOOLS_VERSION:-15859902}
ANDROID_CMDLINE_TOOLS_SHA256=${ANDROID_CMDLINE_TOOLS_SHA256:-4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583}
ANDROID_PLATFORM=${ANDROID_PLATFORM:-android-37.0}
ANDROID_BUILD_TOOLS=${ANDROID_BUILD_TOOLS:-36.0.0}
ANDROID_CMDLINE_TOOLS_URL=${ANDROID_CMDLINE_TOOLS_URL:-https://dl.google.com/android/repository}
FORCE=${FORCE:-false}

if [[ -z ${ANDROID_SDK_ROOT:-} ]]; then
  if is_root; then
    ANDROID_SDK_ROOT=/opt/android-sdk
  else
    ANDROID_SDK_ROOT="$HOME/android-sdk"
  fi
fi

for argument in "$@"; do
  case "$argument" in
    --force) FORCE=true ;;
    --help)
      cat <<EOF
Usage: $0 [--force]

Environment variables:
  ANDROID_SDK_ROOT                SDK location (default: /opt/android-sdk for root)
  ANDROID_PLATFORM                Platform package (default: $ANDROID_PLATFORM)
  ANDROID_BUILD_TOOLS             Build-tools version (default: $ANDROID_BUILD_TOOLS)
  ANDROID_CMDLINE_TOOLS_VERSION   Command-line tools build (default: $ANDROID_CMDLINE_TOOLS_VERSION)
EOF
      exit 0
      ;;
    *) die "Unknown argument: $argument" ;;
  esac
done

ensure_packages ca-certificates curl unzip
require_cmd curl unzip java
require_cmd sha256sum

sdkmanager="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -x "$sdkmanager" || "$FORCE" == "true" ]]; then
  temporary_dir=$(mktemp -d)
  trap 'cleanup_dir "$temporary_dir"' EXIT

  archive="commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip"
  log "Downloading Android command-line tools $ANDROID_CMDLINE_TOOLS_VERSION."
  download "$ANDROID_CMDLINE_TOOLS_URL/$archive" "$temporary_dir/$archive"
  sha256_verify "$temporary_dir/$archive" "$ANDROID_CMDLINE_TOOLS_SHA256"

  mkdir -p "$temporary_dir/extracted"
  unzip -q "$temporary_dir/$archive" -d "$temporary_dir/extracted"

  if is_root; then
    run_root mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
    run_root rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    run_root mv "$temporary_dir/extracted/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  else
    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
    rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    mv "$temporary_dir/extracted/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  fi

  cleanup_dir "$temporary_dir"
  trap - EXIT
fi

sdkmanager="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
[[ -x "$sdkmanager" ]] || die "sdkmanager was not installed correctly."
[[ -w "$ANDROID_SDK_ROOT" ]] || die "Android SDK root is not writable: $ANDROID_SDK_ROOT"

log "Accepting Android SDK licenses."
set +o pipefail
if is_root; then
  yes | "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null 2>&1 || true
else
  yes | "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null 2>&1 || true
fi
set -o pipefail

log "Installing platform-tools, $ANDROID_PLATFORM, and build-tools $ANDROID_BUILD_TOOLS."
if is_root; then
  "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" \
    "platform-tools" \
    "platforms;$ANDROID_PLATFORM" \
    "build-tools;$ANDROID_BUILD_TOOLS"
else
  "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" \
    "platform-tools" \
    "platforms;$ANDROID_PLATFORM" \
    "build-tools;$ANDROID_BUILD_TOOLS"
fi

[[ -d "$ANDROID_SDK_ROOT/platforms/$ANDROID_PLATFORM" ]] || \
  die "Android platform $ANDROID_PLATFORM was not installed."
[[ -d "$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS" ]] || \
  die "Android build-tools $ANDROID_BUILD_TOOLS were not installed."

if is_root && id "${DEV_USER:-vscode}" >/dev/null 2>&1; then
  dev_group=$(id -gn "${DEV_USER:-vscode}")
  chown -R "${DEV_USER:-vscode}:$dev_group" "$ANDROID_SDK_ROOT"
fi

export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_SDK_ROOT
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"
add_path_line "$HOME/.bashrc" "export ANDROID_HOME=\"$ANDROID_SDK_ROOT\""
add_path_line "$HOME/.bashrc" "export ANDROID_SDK_ROOT=\"$ANDROID_SDK_ROOT\""
add_path_line "$HOME/.bashrc" "export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$PATH\""

hash -r 2>/dev/null || true
ok "Android SDK installed at $ANDROID_SDK_ROOT."
ok "adb: $(adb version 2>/dev/null | head -n 1)"
