#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "$3: missing '$2'"; }
assert_eq() { [[ "$1" == "$2" ]] || fail "$3: expected '$2', got '$1'"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
custom="$tmp/gigahash"
config="$custom/gigahash.conf"
mkdir -p "$custom"
cp "$REPO_DIR/h-common.sh" "$custom/h-common.sh"
cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash
CUSTOM_VERSION=2.2.0
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash
EOF

CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='testrig' \
  bash "$REPO_DIR/h-config.sh"
# shellcheck disable=SC1090
. "$config"

assert_eq "$GH_SERVER" 'backup.gigahash.cloud:9100' 'default server'
assert_contains "$(cat "$REPO_DIR/h-manifest.conf")" 'CUSTOM_VERSION=2.2.0' 'manifest version'
assert_contains "$(cat "$REPO_DIR/build.sh")" "VERSION='2.2.0'" 'package version'
assert_contains "$(cat "$REPO_DIR/h-stats.sh")" '"2.2"' 'stats version'

run_script="$(cat "$REPO_DIR/h-run.sh")"
assert_contains "$run_script" 'gigahash-zk-2.2.tar.gz.part-' 'v2.2 mirror URL'
assert_contains "$run_script" '72cacd1f5a23fa4a983f56f0df5eaf9876ebb38a19ca637b94e5c0816e6ec5af' 'v2.2 binary SHA256'

echo 'PASS: GigaHash v2.2 release configuration'
