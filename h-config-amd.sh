#!/usr/bin/env bash
# HiveOS callback: build AMD runtime config from Flight Sheet fields.

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash-amd}"
. "$CUSTOM_DIR/h-manifest.conf"
. "$CUSTOM_DIR/h-common.sh"

server="${CUSTOM_URL:-backup.gigahash.cloud:9100}"
server="$(printf '%s' "$server" | tr '\r\n\t ' ',' | sed -E 's/,+/,/g; s/^,+//; s/,+$//')"
[[ -n "$server" ]] || server="backup.gigahash.cloud:9100"

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
