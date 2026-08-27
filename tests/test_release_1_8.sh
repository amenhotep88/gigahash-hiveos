#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPLIT_DIR="$REPO_DIR/split/gigahash-prl-split"

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "$3: missing '$2'"
}
assert_eq() {
  [[ "$1" == "$2" ]] || fail "$3: expected '$2', got '$1'"
}

test_standard_package_defaults_to_ru1_and_v1_8() {
  local tmp custom config run_script
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash"
  config="$custom/gigahash.conf"
  mkdir -p "$custom"
  cp "$REPO_DIR/h-common.sh" "$custom/h-common.sh"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash
CUSTOM_VERSION=1.8.1
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash
EOF

  CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='testrig' \
    bash "$REPO_DIR/h-config.sh"
  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" 'ru1.gigahash.cloud:9100' 'standard default server'

  run_script="$(cat "$REPO_DIR/h-run.sh")"
  assert_contains "$run_script" "GH_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/gigahash-zk-1.8.tar.gz.part-'" 'standard CDN part URL'
  assert_contains "$run_script" 'GH_PART_LAST=75' 'standard last archive part'
  assert_contains "$run_script" 'ab22159be68dbc9c3dd5a472541f4526bbc41dd5516e746f18a4538282d0e369' 'standard archive SHA256'
  assert_contains "$run_script" 'bd0c9ca5b626fceb1e7c71cb852073a1b4c30cdc6477925947e589d27b19139c' 'standard binary SHA256'
  assert_contains "$run_script" 'cat "$part" >> "$tmp_archive"' 'standard archive assembly'
  [[ "$run_script" != *'cdn.gigahash.cloud'* ]] || fail 'standard package still depends on blocked GigaHash CDN'
  assert_contains "$(cat "$REPO_DIR/h-manifest.conf")" 'CUSTOM_VERSION=1.8.1' 'standard package version'
  assert_contains "$(cat "$REPO_DIR/build.sh")" "VERSION='1.8.1'" 'standard archive version'
  rm -rf "$tmp"
}

test_split_package_defaults_to_ru1_and_v1_8() {
  local tmp custom config run_script
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash-prl-split"
  config="$custom/gigahash-prl-split.conf"
  mkdir -p "$custom"
  cp "$SPLIT_DIR/h-common.sh" "$custom/h-common.sh"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash-prl-split
CUSTOM_VERSION=1.0.4
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash-prl-split
EOF

  CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='redrig' \
    bash "$SPLIT_DIR/h-config.sh"
  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" 'ru1.gigahash.cloud:9100' 'split default server'

  run_script="$(cat "$SPLIT_DIR/h-run.sh")"
  assert_contains "$run_script" "GH_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/gigahash-zk-1.8.tar.gz.part-'" 'split CDN part URL'
  assert_contains "$run_script" 'GH_PART_LAST=75' 'split last archive part'
  assert_contains "$run_script" 'ab22159be68dbc9c3dd5a472541f4526bbc41dd5516e746f18a4538282d0e369' 'split archive SHA256'
  assert_contains "$run_script" 'bd0c9ca5b626fceb1e7c71cb852073a1b4c30cdc6477925947e589d27b19139c' 'split binary SHA256'
  assert_contains "$run_script" 'cat "$part" >> "$tmp_archive"' 'split archive assembly'
  [[ "$run_script" != *'cdn.gigahash.cloud'* ]] || fail 'split package still depends on blocked GigaHash CDN'
  assert_contains "$(cat "$SPLIT_DIR/h-manifest.conf")" 'CUSTOM_VERSION=1.0.4' 'split package version'
  assert_contains "$(cat "$REPO_DIR/build-split.sh")" "VERSION='1.0.4'" 'split archive version'
  assert_contains "$(cat "$SPLIT_DIR/h-stats.sh")" 'split-1.0.4/gh-' 'split stats version'
  rm -rf "$tmp"
}

test_standard_package_defaults_to_ru1_and_v1_8
test_split_package_defaults_to_ru1_and_v1_8
echo 'PASS: GigaHash v1.8 release configuration'
