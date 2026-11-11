#!/usr/bin/env bash
# Keep canonical post-create scripts in sync with their template copies.

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
SCRIPTS_DIR="$ROOT_DIR/scripts"
TEMPLATES_DIR="$ROOT_DIR/templates"
CHECK_ONLY=false
DRIFT=0

for argument in "$@"; do
  case "$argument" in
    --check) CHECK_ONLY=true ;;
    --help)
      printf 'Usage: %s [--check]\n\nCopies canonical scripts into templates.\nUse --check to fail when copies are stale.\n' "$0"
      exit 0
      ;;
    *) printf '[error] Unknown argument: %s\n' "$argument" >&2; exit 2 ;;
  esac
done

sync_file() {
  local source=$1
  local destination=$2
  local mode=$3

  if [[ ! -f "$source" ]]; then
    printf '[error] Missing source file: %s\n' "$source" >&2
    exit 1
  fi

  if [[ "$CHECK_ONLY" == "true" ]]; then
    if [[ ! -f "$destination" ]] || ! cmp -s "$source" "$destination"; then
      printf '[drift] %s is missing or differs from %s\n' \
        "${destination#"$ROOT_DIR"/}" "${source#"$ROOT_DIR"/}" >&2
      DRIFT=1
    fi
    return 0
  fi

  install -D -m "$mode" "$source" "$destination"
}

sync_environment() {
  local environment=$1
  shift
  local script
  local destination_dir="$TEMPLATES_DIR/$environment/.devcontainer"

  sync_file "$SCRIPTS_DIR/common.sh" "$destination_dir/common.sh" 0755
  sync_file "$SCRIPTS_DIR/versions.env" "$destination_dir/versions.env" 0644
  for script in post-create.sh install-opencode.sh "$@"; do
    sync_file "$SCRIPTS_DIR/$script" "$destination_dir/$script" 0755
  done
}

sync_environment react install-common-tools.sh install-node.sh
sync_environment kotlin-android install-java.sh install-gradle.sh install-android-sdk.sh
sync_environment fullstack install-common-tools.sh install-node.sh install-java.sh install-db-clients.sh
sync_environment general-linux install-common-tools.sh install-node.sh

if [[ "$CHECK_ONLY" == "true" ]]; then
  if (( DRIFT != 0 )); then
    printf '[error] Template assets are out of sync. Run scripts/sync-template-assets.sh.\n' >&2
    exit 1
  fi
  printf '[ok] Template scripts are synchronized.\n'
else
  printf '[ok] Template scripts synchronized.\n'
fi
