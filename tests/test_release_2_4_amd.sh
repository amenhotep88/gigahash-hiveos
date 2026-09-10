#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE="$REPO_DIR/gigahash-amd-2.4.0.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

"$REPO_DIR/build-amd.sh" >/dev/null
[[ -s "$PACKAGE" ]] || fail 'AMD v2.4 HiveOS package was not built'

tar -xzf "$PACKAGE" -C "$STAGE"
ROOT="$STAGE/gigahash-amd"

[[ -x "$ROOT/h-config.sh" ]] || fail 'packaged AMD config script is not executable'
[[ -x "$ROOT/h-run.sh" ]] || fail 'packaged AMD run script is not executable'
[[ -x "$ROOT/h-stats.sh" ]] || fail 'packaged AMD stats script is not executable'
grep -qx 'CUSTOM_VERSION=2.4.0-amd1' "$ROOT/h-manifest.conf" || fail 'wrong AMD package version'

source "$ROOT/h-common.sh"
[[ "$(normalize_payout 'wallet-address.amd-rig' 'amd-rig')" == 'wallet-address' ]] || \
  fail 'wallet template suffix was not stripped'

echo 'PASS: GigaHash v2.4 AMD HiveOS package behavior'
