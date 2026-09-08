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
CUSTOM_VERSION=2.3.0
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash
EOF

CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='testrig' \
  bash "$REPO_DIR/h-config.sh"
# shellcheck disable=SC1090
. "$config"

assert_eq "$GH_SERVER" 'backup.gigahash.cloud:9100' 'default server'
assert_contains "$(cat "$REPO_DIR/h-manifest.conf")" 'CUSTOM_VERSION=2.3.0' 'manifest version'
assert_contains "$(cat "$REPO_DIR/build.sh")" "VERSION='2.3.0'" 'package version'
assert_contains "$(cat "$REPO_DIR/h-stats.sh")" '"2.3"' 'stats version'

run_script="$(cat "$REPO_DIR/h-run.sh")"
assert_contains "$run_script" 'gigahash-zk-2.3.tar.gz.part-' 'v2.3 mirror URL'
assert_contains "$run_script" '6234dbf687ee84aa1c9ef3bce798bb61fed961d4b8da6fe24777c901e27a2ae1' 'v2.3 binary SHA256'

workflow="$(cat "$REPO_DIR/.github/workflows/publish-v2.3.yml")"
assert_contains "$workflow" 'releases/2.3/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9' 'official v2.3 URL'
assert_contains "$workflow" "test \"\$(/tmp/gigahash-zk-12.9 --version)\" = 'gigahash-zk 2.3'" 'v2.3 version gate'
assert_contains "$workflow" 'GH_PART_LAST: 57' 'mirror part count gate'

echo 'PASS: GigaHash v2.3 release configuration'
