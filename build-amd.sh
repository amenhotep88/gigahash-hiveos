#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$REPO_DIR/gigahash-amd-2.2.0.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/gigahash-amd"
cp "$REPO_DIR/h-common.sh" "$STAGE/gigahash-amd/"
cp "$REPO_DIR/h-config-amd.sh" "$STAGE/gigahash-amd/h-config.sh"
cp "$REPO_DIR/h-manifest-amd.conf" "$STAGE/gigahash-amd/h-manifest.conf"
cp "$REPO_DIR/h-run-amd.sh" "$STAGE/gigahash-amd/h-run.sh"
cp "$REPO_DIR/h-stats-amd.sh" "$STAGE/gigahash-amd/h-stats.sh"
chmod 755 "$STAGE/gigahash-amd"/h-common.sh "$STAGE/gigahash-amd"/h-config.sh "$STAGE/gigahash-amd"/h-run.sh "$STAGE/gigahash-amd"/h-stats.sh
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 2026-09-03' -C "$STAGE" -czf "$OUTPUT" gigahash-amd
sha256sum "$OUTPUT"
