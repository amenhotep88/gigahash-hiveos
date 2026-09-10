#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "$3: missing '$2'"; }

workflow="$(cat "$REPO_DIR/.github/workflows/publish-v2.2-amd.yml")"
assert_contains "$workflow" 'releases/2.2/ubuntu22.04-rocm10.0.0/gigahash-zk-rocm10.0' 'official v2.2 URL'
assert_contains "$workflow" "test \"\$(/tmp/gigahash-zk-rocm10.0 --version)\" = 'gigahash-zk 2.2'" 'v2.2 version gate'
[[ -f "$REPO_DIR/gigahash-amd-2.2.0.tar.gz" ]] || fail 'AMD v2.2 rollback package must remain available'
[[ -f "$REPO_DIR/vendor/gigahash-zk-rocm10.0-2.2.tar.gz.part-000" ]] || fail 'AMD v2.2 mirror parts must remain available'

echo 'PASS: GigaHash v2.2 AMD release configuration'
