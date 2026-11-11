#!/usr/bin/env bash
# Install OpenJDK 21 and expose it through a stable JAVA_HOME.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

: "${JAVA_MAJOR:?JAVA_MAJOR is not set; ensure scripts/versions.env is present.}"
JAVA_HOME_LINK=${JAVA_HOME_LINK:-/opt/java/openjdk}
FORCE=${FORCE:-false}

for argument in "$@"; do
  case "$argument" in
    --force) FORCE=true ;;
    --help)
      printf 'Usage: %s [--force]\n\nInstalls OpenJDK %s JDK (headless) via apt.\n' \
        "$0" "$JAVA_MAJOR"
      exit 0
      ;;
    *) die "Unknown argument: $argument" ;;
  esac
done

current_major=""
if have java && have javac; then
  java_version=$(java -version 2>&1 | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
  current_major=$(version_major "$java_version")
fi

if [[ "$current_major" == "$JAVA_MAJOR" && "$FORCE" != "true" ]]; then
  ok "OpenJDK $JAVA_MAJOR is already installed."
else
  log "Installing OpenJDK $JAVA_MAJOR JDK (headless)."
  ensure_packages "openjdk-${JAVA_MAJOR}-jdk-headless"
fi

require_cmd java javac

javac_path=$(readlink -f "$(command -v javac)")
detected_java_home=$(dirname "$(dirname "$javac_path")")
[[ -x "$detected_java_home/bin/java" ]] || die "Could not determine JAVA_HOME from javac."

run_root mkdir -p "$(dirname "$JAVA_HOME_LINK")"
run_root ln -sfn "$detected_java_home" "$JAVA_HOME_LINK"

export JAVA_HOME="$JAVA_HOME_LINK"
export PATH="$JAVA_HOME/bin:$PATH"
add_path_line "$HOME/.bashrc" "export JAVA_HOME=\"$JAVA_HOME_LINK\""
add_path_line "$HOME/.bashrc" "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
add_path_line "$HOME/.profile" "export JAVA_HOME=\"$JAVA_HOME_LINK\""
add_path_line "$HOME/.profile" "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
if [[ -f "$HOME/.zshrc" ]]; then
  add_path_line "$HOME/.zshrc" "export JAVA_HOME=\"$JAVA_HOME_LINK\""
  add_path_line "$HOME/.zshrc" "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
fi

hash -r 2>/dev/null || true
ok "Java: $(java -version 2>&1 | head -n 1)"
ok "JAVA_HOME: $JAVA_HOME"
