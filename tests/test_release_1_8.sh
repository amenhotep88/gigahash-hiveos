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
CUSTOM_VERSION=1.8.0
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash
EOF

  CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='testrig' \
    bash "$REPO_DIR/h-config.sh"
  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" 'ru1.gigahash.cloud:9100' 'standard default server'

  run_script="$(cat "$REPO_DIR/h-run.sh")"
  assert_contains "$run_script" '/releases/1.8/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9' 'standard v1.8 URL'
  assert_contains "$run_script" 'bd0c9ca5b626fceb1e7c71cb852073a1b4c30cdc6477925947e589d27b19139c' 'standard v1.8 SHA256'
  assert_contains "$(cat "$REPO_DIR/h-manifest.conf")" 'CUSTOM_VERSION=1.8.0' 'standard package version'
  assert_contains "$(cat "$REPO_DIR/build.sh")" "VERSION='1.8'" 'standard archive version'
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
CUSTOM_VERSION=1.0.2
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash-prl-split
EOF

  CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='redrig' \
    bash "$SPLIT_DIR/h-config.sh"
  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" 'ru1.gigahash.cloud:9100' 'split default server'

  run_script="$(cat "$SPLIT_DIR/h-run.sh")"
  assert_contains "$run_script" '/releases/1.8/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9' 'split v1.8 URL'
  assert_contains "$run_script" 'bd0c9ca5b626fceb1e7c71cb852073a1b4c30cdc6477925947e589d27b19139c' 'split v1.8 SHA256'
  assert_contains "$(cat "$SPLIT_DIR/h-manifest.conf")" 'CUSTOM_VERSION=1.0.2' 'split package version'
  assert_contains "$(cat "$REPO_DIR/build-split.sh")" "VERSION='1.0.2'" 'split archive version'
  assert_contains "$(cat "$SPLIT_DIR/h-stats.sh")" 'split-1.0.2/gh-' 'split stats version'
  rm -rf "$tmp"
}

test_standard_package_defaults_to_ru1_and_v1_8
test_split_package_defaults_to_ru1_and_v1_8
echo 'PASS: GigaHash v1.8 release configuration'
