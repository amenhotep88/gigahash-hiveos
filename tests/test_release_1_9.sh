#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPLIT_DIR="$REPO_DIR/split/gigahash-prl-split"

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

test_split_package_defaults_to_ru1_v1_9_and_low_cpu() {
  local tmp custom config run_script
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash-prl-split"
  config="$custom/gigahash-prl-split.conf"
  mkdir -p "$custom"
  cp "$SPLIT_DIR/h-common.sh" "$custom/h-common.sh"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash-prl-split
CUSTOM_VERSION=1.0.5
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash-prl-split
EOF

  CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='redrig' \
    bash "$SPLIT_DIR/h-config.sh"
  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" 'ru1.gigahash.cloud:9100' 'split default server'

  run_script="$(cat "$SPLIT_DIR/h-run.sh")"
  assert_contains "$run_script" "GH_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/gigahash-zk-1.9.tar.gz.part-'" 'split CDN part URL'
  assert_contains "$run_script" 'GH_PART_LAST=79' 'split last archive part'
  assert_contains "$run_script" '4f45a46f2515a7f5c77a764679bf5de0e79f77505ee5d0f59ce6b9338d6f8730' 'split archive SHA256'
  assert_contains "$run_script" '3bc91c3806d244d9d5795bd9a2ddaed1ee57391182113978dd14ed3e9b972121' 'split binary SHA256'
  assert_contains "$run_script" 'cat "$part" >> "$tmp_archive"' 'split archive assembly'
  assert_not_contains "$run_script" 'cdn.gigahash.cloud' 'split package direct CDN dependency'
  assert_contains "$run_script" '--low-cpu' 'split NOCK low-cpu args'
  assert_contains "$(cat "$SPLIT_DIR/h-manifest.conf")" 'CUSTOM_VERSION=1.0.5' 'split package version'
  assert_contains "$(cat "$REPO_DIR/build-split.sh")" "VERSION='1.0.5'" 'split archive version'
  assert_contains "$(cat "$SPLIT_DIR/h-stats.sh")" 'split-1.0.5/gh-' 'split stats version'
  rm -rf "$tmp"
}

test_standard_package_defaults_to_ru1_and_v1_9
test_split_package_defaults_to_ru1_v1_9_and_low_cpu
echo 'PASS: GigaHash v1.9 release configuration'
