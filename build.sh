#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NAME='gigahash'
VERSION='1.9.0'
OUTPUT="$REPO_DIR/${PACKAGE_NAME}-${VERSION}.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/$PACKAGE_NAME"
cp "$REPO_DIR"/h-common.sh "$REPO_DIR"/h-config.sh "$REPO_DIR"/h-manifest.conf \
  "$REPO_DIR"/h-run.sh "$REPO_DIR"/h-stats.sh "$STAGE/$PACKAGE_NAME/"
chmod 755 "$STAGE/$PACKAGE_NAME"/h-common.sh "$STAGE/$PACKAGE_NAME"/h-config.sh \
  "$STAGE/$PACKAGE_NAME"/h-run.sh "$STAGE/$PACKAGE_NAME"/h-stats.sh
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 2026-08-28' \
  -C "$STAGE" -czf "$OUTPUT" "$PACKAGE_NAME"
sha256sum "$OUTPUT"
