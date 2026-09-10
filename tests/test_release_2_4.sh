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
CUSTOM_VERSION=2.4.0
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash
EOF

CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='testrig' \
  bash "$REPO_DIR/h-config.sh"
# shellcheck disable=SC1090
. "$config"

assert_eq "$GH_SERVER" 'backup.gigahash.cloud:9100' 'default server'
assert_contains "$(cat "$REPO_DIR/h-manifest.conf")" 'CUSTOM_VERSION=2.4.0' 'manifest version'
assert_contains "$(cat "$REPO_DIR/build.sh")" "VERSION='2.4.0'" 'package version'
assert_contains "$(cat "$REPO_DIR/h-stats.sh")" '"2.4"' 'stats version'

run_script="$(cat "$REPO_DIR/h-run.sh")"
assert_contains "$run_script" 'gigahash-zk-2.4.tar.gz.part-' 'v2.4 mirror URL'
assert_contains "$run_script" '372fb8fbe72c4a493016dc8d1fa6f54e2a16ae028bb32ca7f8fa02c62d6f660a' 'v2.4 binary SHA256'
assert_contains "$run_script" '8f004ac4a3d17470ae98aaf60cd82fb83c156a363e735027c96088334204d041' 'v2.4 archive SHA256'

workflow="$(cat "$REPO_DIR/.github/workflows/publish-v2.4.yml")"
assert_contains "$workflow" 'releases/2.4/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9' 'official v2.4 URL'
assert_contains "$workflow" "test \"\$(/tmp/gigahash-zk-12.9 --version)\" = 'gigahash-zk 2.4'" 'v2.4 version gate'
assert_contains "$workflow" 'GH_PART_LAST: 58' 'mirror part count gate'

echo 'PASS: GigaHash v2.4 release configuration'
