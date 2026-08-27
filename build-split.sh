#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NAME='gigahash-prl-split'
VERSION='1.0.3'
SOURCE_DIR="$REPO_DIR/split/$PACKAGE_NAME"
OUTPUT="$REPO_DIR/${PACKAGE_NAME}-${VERSION}.tar.gz"

chmod 755 "$SOURCE_DIR/h-config.sh" "$SOURCE_DIR/h-run.sh" "$SOURCE_DIR/h-stats.sh" "$SOURCE_DIR/h-common.sh"
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 2026-08-27' \
  -C "$REPO_DIR/split" -czf "$OUTPUT" "$PACKAGE_NAME"
sha256sum "$OUTPUT"
