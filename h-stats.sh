#!/usr/bin/env bash
# HiveOS callback. Must define $khs and $stats when sourced by the agent.

CUSTOM_DIR="/hive/miners/custom/gigahash"
[[ -f "$CUSTOM_DIR/h-manifest.conf" ]] && . "$CUSTOM_DIR/h-manifest.conf"
LOG="${CUSTOM_LOG_BASENAME:-/var/log/miner/gigahash/gigahash}.log"
NATIVE_STATS="${CUSTOM_LOG_BASENAME:-/var/log/miner/gigahash/gigahash}.json"

khs=0
stats='null'

if [[ -s "$NATIVE_STATS" ]] && command -v jq >/dev/null 2>&1 && jq -e . "$NATIVE_STATS" >/dev/null 2>&1; then
  khs="$(jq -r '(.hashrate // 0) / 1000' "$NATIVE_STATS")"
  hs_json="$(jq -c '[.gpus[]? | ((.hashrate // 0) / 1000)]' "$NATIVE_STATS")"
  temp_json="$(jq -c '[.gpus[]? | (.temperature_celsius // 0)]' "$NATIVE_STATS")"
  fan_json="$(jq -c '[.gpus[]? | (.fan_percent // 0)]' "$NATIVE_STATS")"
  uptime="$(jq -r '.uptime_seconds // 0' "$NATIVE_STATS")"
  miner_ver="$(jq -r '.miner_version // "2.2"' "$NATIVE_STATS")"
  stats="$(printf '{"hs":%s,"hs_units":"khs","temp":%s,"fan":%s,"uptime":%s,"ver":"%s"}' \
    "$hs_json" "$temp_json" "$fan_json" "$uptime" "$miner_ver")"
elif [[ -s "$LOG" ]]; then
  last_total="$(grep -E 'Total[[:space:]]+[0-9.]+[[:space:]]+(p/s|kp/s|Mp/s)' "$LOG" | tail -n 1)"
  if [[ "$last_total" =~ Total[[:space:]]+([0-9.]+)[[:space:]]+(p/s|kp/s|Mp/s) ]]; then
    total_value="${BASH_REMATCH[1]}"
    total_unit="${BASH_REMATCH[2]}"
    khs="$(awk -v v="$total_value" -v u="$total_unit" 'BEGIN {
      if (u=="p/s") v=v/1000;
      else if (u=="Mp/s") v=v*1000;
      printf "%.3f", v;
    }')"
  fi

  # Read only the latest table region. Repeated GPU ids overwrite older rows,
  # so the final values are from the newest complete/partial table.
  parsed="$(tail -n 220 "$LOG" | awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    $2 ~ /^[ \t]*[0-9]+[ \t]*$/ && $3 ~ /p\/s/ {
      id=trim($2)+0
      split(trim($3), a, /[ \t]+/)
      v=a[1]+0; u=a[2]
      if (u=="p/s") v=v/1000
      else if (u=="Mp/s") v=v*1000
      rate[id]=v

      t=trim($5); sub(/[ \t]*C.*/, "", t); temp[id]=t+0
      f=trim($6); sub(/%.*/, "", f); fan[id]=f+0
      if (!(id in seen)) { seen[id]=1; count++ }
      if (id>max) max=id
    }
    END {
      hs="["; ts="["; fs="["; first=1
      for (i=0; i<=max; i++) if (i in rate) {
        if (!first) { hs=hs ","; ts=ts ","; fs=fs "," }
        hs=hs sprintf("%.3f", rate[i]); ts=ts temp[i]; fs=fs fan[i]
        first=0
      }
      hs=hs "]"; ts=ts "]"; fs=fs "]"
      print hs "\t" ts "\t" fs
    }')"

  IFS=$'\t' read -r hs_json temp_json fan_json <<< "$parsed"
  [[ -n "${hs_json:-}" ]] || hs_json='[]'
  [[ -n "${temp_json:-}" ]] || temp_json='[]'
  [[ -n "${fan_json:-}" ]] || fan_json='[]'

  uptime=0
  pid="$(pgrep -f '/hive/miners/custom/gigahash/gigahash-zk-12.9' | head -n 1)"
  if [[ -n "$pid" ]]; then
    uptime="$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')"
  fi
  [[ "$uptime" =~ ^[0-9]+$ ]] || uptime=0

  # The miner's local Accepted counter can remain zero while pool-side shares
  # are already VALID, so don't publish misleading ar[] counters to HiveOS.
  stats="$(printf '{"hs":%s,"hs_units":"khs","temp":%s,"fan":%s,"uptime":%s,"ver":"2.2"}' \
    "$hs_json" "$temp_json" "$fan_json" "$uptime")"
fi

# Helpful when run manually in shell; silent when sourced by Hive agent.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "khs=$khs"
  echo "$stats"
fi
