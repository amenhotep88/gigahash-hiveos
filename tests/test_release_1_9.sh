#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "$3: missing '$2'"
}
assert_not_contains() {
  [[ "$1" != *"$2"* ]] || fail "$3: unexpectedly contains '$2'"
}
assert_eq() {
  [[ "$1" == "$2" ]] || fail "$3: expected '$2', got '$1'"
}

test_standard_package_defaults_to_ru1_and_v1_9() {
  local tmp custom config run_script
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash"
  config="$custom/gigahash.conf"
  mkdir -p "$custom"
  cp "$REPO_DIR/h-common.sh" "$custom/h-common.sh"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash
CUSTOM_VERSION=1.9.0
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash
EOF

  CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='testrig' \
    bash "$REPO_DIR/h-config.sh"
  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" 'ru1.gigahash.cloud:9100' 'standard default server'

  run_script="$(cat "$REPO_DIR/h-run.sh")"
  assert_contains "$run_script" "GH_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/gigahash-zk-1.9.tar.gz.part-'" 'standard CDN part URL'
  assert_contains "$run_script" 'GH_PART_LAST=79' 'standard last archive part'
  assert_contains "$run_script" '4f45a46f2515a7f5c77a764679bf5de0e79f77505ee5d0f59ce6b9338d6f8730' 'standard archive SHA256'
  assert_contains "$run_script" '3bc91c3806d244d9d5795bd9a2ddaed1ee57391182113978dd14ed3e9b972121' 'standard binary SHA256'
  assert_contains "$run_script" 'cat "$part" >> "$tmp_archive"' 'standard archive assembly'
  assert_not_contains "$run_script" 'cdn.gigahash.cloud' 'standard package direct CDN dependency'
  assert_not_contains "$run_script" '--low-cpu' 'standard package forced low-cpu mode'
  assert_contains "$(cat "$REPO_DIR/h-manifest.conf")" 'CUSTOM_VERSION=1.9.0' 'standard package version'
  assert_contains "$(cat "$REPO_DIR/build.sh")" "VERSION='1.9.0'" 'standard archive version'
  assert_contains "$(cat "$REPO_DIR/h-stats.sh")" '"1.9"' 'standard stats version'
  rm -rf "$tmp"
}

test_retired_split_is_absent() {
  [[ ! -e "$REPO_DIR/build-split.sh" ]] || fail 'retired split build script still exists'
  [[ ! -e "$REPO_DIR/split" ]] || fail 'retired split source directory still exists'
  [[ ! -e "$REPO_DIR/tests/test_split_wrapper.sh" ]] || fail 'retired split test still exists'

  if compgen -G "$REPO_DIR/gigahash-prl-split-*.tar.gz" >/dev/null; then
    fail 'retired split package still exists'
  fi
  if compgen -G "$REPO_DIR/vendor/srbminer_custom-*" >/dev/null; then
    fail 'retired SRBMiner vendor archive still exists'
  fi
}

test_standard_package_defaults_to_ru1_and_v1_9
test_retired_split_is_absent
echo 'PASS: GigaHash v1.9 release configuration'
