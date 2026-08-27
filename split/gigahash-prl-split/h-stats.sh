#!/usr/bin/env bash
# HiveOS callback: expose NOCK proof rate. PRL uses different hash units and
# remains available in the SRBMiner console/API and on the Kryptex dashboard.

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash-prl-split}"
[[ -f "$CUSTOM_DIR/h-manifest.conf" ]] && . "$CUSTOM_DIR/h-manifest.conf"
NATIVE_STATS="${CUSTOM_LOG_BASENAME:-/var/log/miner/gigahash-prl-split/gigahash-prl-split}-nock.json"

khs=0
stats='null'

if [[ -s "$NATIVE_STATS" ]] && command -v jq >/dev/null 2>&1 && jq -e . "$NATIVE_STATS" >/dev/null 2>&1; then
  khs="$(jq -r '(.hashrate // 0) / 1000' "$NATIVE_STATS")"
  hs_json="$(jq -c '[.gpus[]? | ((.hashrate // 0) / 1000)]' "$NATIVE_STATS")"
  temp_json="$(jq -c '[.gpus[]? | (.temperature_celsius // 0)]' "$NATIVE_STATS")"
  fan_json="$(jq -c '[.gpus[]? | (.fan_percent // 0)]' "$NATIVE_STATS")"
  uptime="$(jq -r '.uptime_seconds // 0' "$NATIVE_STATS")"
  miner_ver="$(jq -r '.miner_version // "1.7"' "$NATIVE_STATS")"
  stats="$(printf '{"hs":%s,"hs_units":"khs","temp":%s,"fan":%s,"uptime":%s,"ver":"split-1.0.0/gh-%s","algo":"nock-zk"}' \
    "$hs_json" "$temp_json" "$fan_json" "$uptime" "$miner_ver")"
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "khs=$khs"
  echo "$stats"
fi
