#!/usr/bin/env bash
# Install the full toolchain while the Dockerfile builds the image.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

profile=${1:-all}
log "post-create: user=$(id -un), HOME=$HOME, profile=$profile"

[[ "$profile" == "all" ]] || die "Usage: $0 [all]"

bash "$SCRIPT_DIR/install-common-tools.sh"
bash "$SCRIPT_DIR/install-node.sh"
bash "$SCRIPT_DIR/install-java.sh"
bash "$SCRIPT_DIR/install-gradle.sh"
bash "$SCRIPT_DIR/install-android-sdk.sh"
bash "$SCRIPT_DIR/install-opencode.sh"

ok "Post-create setup complete for the $profile profile."
