#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$REPO_DIR/gigahash-amd-2.4.0.tar.gz" ]] || fail 'AMD v2.4 rollback package must remain available'
[[ -f "$REPO_DIR/vendor/gigahash-zk-amd-2.4.tar.gz.part-000" ]] || fail 'AMD v2.4 mirror parts must remain available'
[[ -f "$REPO_DIR/vendor/gigahash-zk-amd-2.4.tar.gz.part-136" ]] || fail 'AMD v2.4 mirror part range is incomplete'
[[ -f "$REPO_DIR/.github/workflows/publish-v2.4-amd.yml" ]] || fail 'AMD v2.4 workflow must remain available'

echo 'PASS: GigaHash v2.4 AMD rollback assets'
