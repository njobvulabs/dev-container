#!/usr/bin/env bash
# Lightweight tests for repository helpers. Safe to run on any machine; no
# network access or system package installation is required.

set -Eeuo pipefail

TEST_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "$TEST_DIR/.." && pwd)
TESTS_RUN=0
TESTS_FAILED=0

assert_eq() {
  local expected=$1
  local actual=$2
  local message=$3

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$actual" != "$expected" ]]; then
    printf '[error] %s\n  expected: %s\n  actual:   %s\n' \
      "$message" "$expected" "$actual" >&2
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    printf '[ok] %s\n' "$message"
  fi
}

assert_nonempty() {
  local value=$1
  local message=$2

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -z "$value" ]]; then
    printf '[error] %s\n' "$message" >&2
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    printf '[ok] %s\n' "$message"
  fi
}

temporary_dir=$(mktemp -d)
trap 'rm -rf "$temporary_dir"' EXIT

# Source common.sh the same way the installers do.
SCRIPT_DIR="$ROOT_DIR/scripts"
# shellcheck source=scripts/common.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

assert_eq "21" "$(version_major "21.0.1")" "version_major handles modern JDKs"
assert_eq "8" "$(version_major "1.8.0_402")" "version_major handles legacy 1.x versions"
assert_nonempty "${NODE_VERSION:-}" "versions.env defines NODE_VERSION"
assert_nonempty "${OPENCODE_VERSION:-}" "versions.env defines OPENCODE_VERSION"

expected_arch=""
case "$(uname -m)" in
  x86_64 | amd64) expected_arch="x64" ;;
  aarch64 | arm64) expected_arch="arm64" ;;
  *) expected_arch="unsupported" ;;
esac
if [[ "$expected_arch" != "unsupported" ]]; then
  assert_eq "$expected_arch" "$(detect_arch)" "detect_arch maps the current architecture"
fi

shell_rc="$temporary_dir/bashrc"
# The literal $PATH is intentional: add_path_line must preserve the text.
# shellcheck disable=SC2016
add_path_line "$shell_rc" 'export PATH="/opt/example:$PATH"'
# shellcheck disable=SC2016
add_path_line "$shell_rc" 'export PATH="/opt/example:$PATH"'
# shellcheck disable=SC2016
assert_eq "1" "$(grep -Fc 'export PATH="/opt/example:$PATH"' "$shell_rc")" \
  "add_path_line does not duplicate lines"

printf 'payload\n' >"$temporary_dir/source"
download "file://$temporary_dir/source" "$temporary_dir/downloaded"
assert_eq "payload" "$(cat "$temporary_dir/downloaded")" "download writes the destination file"
if [[ -e "$temporary_dir/downloaded.part" ]]; then
  part_state="present"
else
  part_state="absent"
fi
assert_eq "absent" "$part_state" "download removes the partial file"

# Exercise the OpenCode installer end to end with a stand-in upstream script.
fake_installer="$temporary_dir/fake-opencode-install.sh"
cat >"$fake_installer" <<'FAKE_INSTALLER'
#!/usr/bin/env bash
set -Eeuo pipefail
install_dir=${OPENCODE_INSTALL_DIR:?OPENCODE_INSTALL_DIR is required}
version=unknown
while (($# > 0)); do
  case "$1" in
    --version) version=$2; shift 2 ;;
    --no-modify-path) shift ;;
    *) shift ;;
  esac
done
mkdir -p "$install_dir"
printf '#!/usr/bin/env bash\necho "opencode v%s"\n' "$version" >"$install_dir/opencode"
chmod +x "$install_dir/opencode"
FAKE_INSTALLER
fake_hash=$(sha256sum "$fake_installer" | cut -d' ' -f1)
fake_home="$temporary_dir/opencode-home"
fake_bin="$temporary_dir/opencode-bin"

if HOME="$fake_home" OPENCODE_INSTALL_DIR="$fake_bin" \
  OPENCODE_INSTALL_URL="file://$fake_installer" \
  OPENCODE_INSTALL_SHA256="$fake_hash" OPENCODE_VERSION=9.9.9 \
  "$SCRIPT_DIR/install-opencode.sh" >/dev/null 2>&1; then
  install_state="installed"
else
  install_state="failed"
fi
assert_eq "installed" "$install_state" "install-opencode.sh installs with a verified installer"
assert_eq "opencode v9.9.9" "$("$fake_bin/opencode" --version)" \
  "verified OpenCode install reports the pinned version"

if HOME="$fake_home" OPENCODE_INSTALL_DIR="$fake_bin" \
  OPENCODE_INSTALL_URL="file://$fake_installer" \
  OPENCODE_INSTALL_SHA256=deadbeef OPENCODE_VERSION=9.9.9 \
  "$SCRIPT_DIR/install-opencode.sh" --force >/dev/null 2>&1; then
  checksum_state="unexpected-success"
else
  checksum_state="rejected"
fi
assert_eq "rejected" "$checksum_state" "install-opencode.sh rejects a bad installer checksum"

if "$ROOT_DIR/scripts/sync-template-assets.sh" --check >/dev/null 2>&1; then
  sync_state="synchronized"
else
  sync_state="drifted"
fi
assert_eq "synchronized" "$sync_state" "template assets are synchronized"

for installer in "$SCRIPT_DIR"/install-*.sh; do
  [[ -f "$installer" ]] || continue
  if bash "$installer" --help >/dev/null 2>&1; then
    help_state="ok"
  else
    help_state="failed"
  fi
  assert_eq "ok" "$help_state" "$(basename "$installer") --help"
done

if ((TESTS_FAILED > 0)); then
  printf '\n%d of %d tests failed.\n' "$TESTS_FAILED" "$TESTS_RUN" >&2
  exit 1
fi

printf '\nAll %d tests passed.\n' "$TESTS_RUN"
