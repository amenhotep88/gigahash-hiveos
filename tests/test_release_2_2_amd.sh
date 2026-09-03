#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "$3: missing '$2'"; }

[[ -x "$REPO_DIR/build-amd.sh" ]] || fail 'build-amd.sh missing or not executable'
assert_contains "$(cat "$REPO_DIR/h-run-amd.sh")" 'gigahash-zk-rocm10.0' 'ROCm binary'
assert_contains "$(cat "$REPO_DIR/h-run-amd.sh")" 'a9bcf774b394956ef2eb0af15d9886e976abd5ab04c27d0eb5b990e9b7427019' 'ROCm binary SHA256'
assert_contains "$(cat "$REPO_DIR/h-run-amd.sh")" 'gigahash-zk-rocm10.0-2.2.tar.gz.part-' 'ROCm mirror URL'
assert_contains "$(cat "$REPO_DIR/h-manifest-amd.conf")" 'CUSTOM_NAME=gigahash-amd' 'AMD custom miner name'
assert_contains "$(cat "$REPO_DIR/h-manifest-amd.conf")" 'CUSTOM_VERSION=2.2.0-amd1' 'AMD package version'
assert_contains "$(cat "$REPO_DIR/h-stats-amd.sh")" '/hive/miners/custom/gigahash-amd/gigahash-zk-rocm10.0' 'AMD stats process path'

echo 'PASS: GigaHash v2.2 AMD release configuration'
