#!/usr/bin/env bash
set -euo pipefail

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash-prl-split}"
. "$CUSTOM_DIR/h-manifest.conf"
. "$CUSTOM_DIR/h-common.sh"

server="${CUSTOM_URL:-84.32.220.164:9100}"
server="$(printf '%s' "$server" | tr -d '\r\n\t ')"
[[ -n "$server" ]] || server='84.32.220.164:9100'

worker="${WORKER_NAME:-$(hostname)}"
payout="$(normalize_payout "${CUSTOM_TEMPLATE:-}" "$worker")"

cat > "$CUSTOM_CONFIG_FILENAME" <<CFG
GH_SERVER=$(printf '%q' "$server")
GH_PAYOUT=$(printf '%q' "$payout")
GH_WORKER=$(printf '%q' "${worker}-NOCK")
GH_DEVICES=0,1,2,3
GH_INSTANCES=2
PRL_POOL=prl-ru.kryptex.network:7048
PRL_WALLET=prl1pq2g5uzwq8uth2l6f5tzw0v85re5qmatw5y9uqy38pmfz2dnlvkhseq95q9
PRL_WORKER=$(printf '%q' "${worker}-PRL")
PRL_DEVICES=4,5,6,7
CFG
