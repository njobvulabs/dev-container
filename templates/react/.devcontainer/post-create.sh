#!/usr/bin/env bash
# Install the selected template's toolchain inside a Codespace or Dev Container.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

profile=${1:-}

case "$profile" in
  react)
    bash "$SCRIPT_DIR/install-node.sh"
    bash "$SCRIPT_DIR/install-opencode.sh"
    ;;
  kotlin-android)
    bash "$SCRIPT_DIR/install-java.sh"
    bash "$SCRIPT_DIR/install-gradle.sh"
    bash "$SCRIPT_DIR/install-android-sdk.sh"
    bash "$SCRIPT_DIR/install-opencode.sh"
    ;;
  fullstack)
    bash "$SCRIPT_DIR/install-node.sh"
    bash "$SCRIPT_DIR/install-java.sh"
    bash "$SCRIPT_DIR/install-opencode.sh"
    ;;
  general-linux)
    bash "$SCRIPT_DIR/install-node.sh"
    bash "$SCRIPT_DIR/install-opencode.sh"
    ;;
  *)
    die "Usage: $0 <react|kotlin-android|fullstack|general-linux>"
    ;;
esac

ok "Post-create setup complete for the $profile template."
