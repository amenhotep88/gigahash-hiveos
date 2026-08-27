#!/usr/bin/env bash
# HiveOS callback: build runtime config from Flight Sheet fields.

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash}"
. "$CUSTOM_DIR/h-manifest.conf"
. "$CUSTOM_DIR/h-common.sh"

# Pool URL field. GigaHash accepts HOST:PORT or comma-separated HOST:PORT list.
server="${CUSTOM_URL:-ru1.gigahash.cloud:9100}"
server="$(printf '%s' "$server" | tr '\r\n\t ' ',' | sed -E 's/,+/,/g; s/^,+//; s/,+$//')"
[[ -n "$server" ]] || server="ru1.gigahash.cloud:9100"

# For this integration, Wallet and worker template should be %WAL% only.
payout="${CUSTOM_TEMPLATE:-}"
worker="${WORKER_NAME:-$(hostname)}"
extra="${CUSTOM_USER_CONFIG:-}"
payout="$(normalize_payout "$payout" "$worker")"

cat > "$CUSTOM_CONFIG_FILENAME" <<CFG
GH_SERVER=$(printf '%q' "$server")
GH_PAYOUT=$(printf '%q' "$payout")
GH_WORKER=$(printf '%q' "$worker")
GH_EXTRA=$(printf '%q' "$extra")
CFG
