#!/usr/bin/env bash
# HiveOS callback: expose NOCK as the primary algorithm and PearlHash as the
# secondary algorithm. The two rates use different units and GPU bus mappings.

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash-prl-split}"
[[ -f "$CUSTOM_DIR/h-manifest.conf" ]] && . "$CUSTOM_DIR/h-manifest.conf"
NATIVE_STATS="${CUSTOM_LOG_BASENAME:-/var/log/miner/gigahash-prl-split/gigahash-prl-split}-nock.json"
SRB_API='http://127.0.0.1:21550'

khs=0
khs2=0
stats='null'

merge_srb_stats() {
  local primary_stats="$1" srb_stats="$2" agent_gpu_stats="$3"
  local prl_ids prl_hs_json prl_bus_json prl_total_khs prl_algo
  local prl_accepted prl_rejected all_temp_json all_fan_json
  local prl_temp_json prl_fan_json

  prl_ids="$(jq -ce '[.gpu_devices[]?.id] |
    select(length > 0 and all(.[]; type == "number"))' <<< "$srb_stats")" || return 1
  prl_hs_json="$(jq -ce '[.gpu_devices[]?.id as $id |
    (.algorithms[0].hashrate.gpu[("gpu" + ($id | tostring))] // 0)] |
    select(all(.[]; type == "number")) | map(. / 1000)' <<< "$srb_stats")" || return 1
  prl_bus_json="$(jq -ce '[.gpu_devices[]?.bus_id] |
    select(length > 0 and all(.[]; type == "number"))' <<< "$srb_stats")" || return 1
  prl_total_khs="$(jq -er '(.algorithms[0].hashrate.now // .algorithms[0].hashrate["1min"] // 0) |
    select(type == "number") | . / 1000' <<< "$srb_stats")" || return 1
  prl_algo="$(jq -er '(.algorithms[0].name // "pearlhash") |
    select(type == "string" and length > 0)' <<< "$srb_stats")" || return 1
  prl_accepted="$(jq -er '(.algorithms[0].shares.accepted // 0) |
    select(type == "number")' <<< "$srb_stats")" || return 1
  prl_rejected="$(jq -er '(.algorithms[0].shares.rejected // 0) |
    select(type == "number")' <<< "$srb_stats")" || return 1

  [[ -n "$agent_gpu_stats" ]] || agent_gpu_stats='{}'
  all_temp_json="$(jq -c '.temp // []' <<< "$agent_gpu_stats" 2>/dev/null || printf '[]')"
  all_fan_json="$(jq -c '.fan // []' <<< "$agent_gpu_stats" 2>/dev/null || printf '[]')"
  prl_temp_json="$(jq -cn --argjson ids "$prl_ids" --argjson values "$all_temp_json" \
    '[$ids[] as $id | $values[$id] // 0 | if type == "number" then . else 0 end]')" || return 1
  prl_fan_json="$(jq -cn --argjson ids "$prl_ids" --argjson values "$all_fan_json" \
    '[$ids[] as $id | $values[$id] // 0 | if type == "number" then . else 0 end]')" || return 1

  jq -ce \
    --argjson total_khs2 "$prl_total_khs" \
    --argjson hs2 "$prl_hs_json" \
    --argjson temp2 "$prl_temp_json" \
    --argjson fan2 "$prl_fan_json" \
    --argjson ar2 "[$prl_accepted,$prl_rejected]" \
    --argjson bus_numbers2 "$prl_bus_json" \
    --arg algo2 "$prl_algo" \
    '. + {
      total_khs2: $total_khs2,
      hs2: $hs2,
      hs_units2: "khs",
      temp2: $temp2,
      fan2: $fan2,
      ar2: $ar2,
      algo2: $algo2,
      bus_numbers2: $bus_numbers2
    }' <<< "$primary_stats"
}

if [[ -s "$NATIVE_STATS" ]] && command -v jq >/dev/null 2>&1 && jq -e . "$NATIVE_STATS" >/dev/null 2>&1; then
  khs="$(jq -r '(.hashrate // 0) / 1000' "$NATIVE_STATS")"
  hs_json="$(jq -c '[.gpus[]? | ((.hashrate // 0) / 1000)]' "$NATIVE_STATS")"
  temp_json="$(jq -c '[.gpus[]? | (.temperature_celsius // 0)]' "$NATIVE_STATS")"
  fan_json="$(jq -c '[.gpus[]? | (.fan_percent // 0)]' "$NATIVE_STATS")"
  uptime="$(jq -r '.uptime_seconds // 0' "$NATIVE_STATS")"
  miner_ver="$(jq -r '.miner_version // "1.9"' "$NATIVE_STATS")"
  stats="$(printf '{"hs":%s,"hs_units":"khs","temp":%s,"fan":%s,"uptime":%s,"ver":"split-1.0.5/gh-%s","algo":"nock-zk"}' \
    "$hs_json" "$temp_json" "$fan_json" "$uptime" "$miner_ver")"
fi

if [[ "$stats" != 'null' ]] && command -v curl >/dev/null 2>&1; then
  srb_stats="$(curl --connect-timeout 2 --max-time 3 --silent --noproxy '*' "$SRB_API" 2>/dev/null || true)"
  if [[ -n "$srb_stats" ]] && jq -e . <<< "$srb_stats" >/dev/null 2>&1; then
    if merged_stats="$(merge_srb_stats "$stats" "$srb_stats" "${gpu_stats:-}" 2>/dev/null)"; then
      stats="$merged_stats"
      khs2="$(jq -r '.total_khs2 // 0' <<< "$stats")"
    fi
  fi
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "khs=$khs"
  echo "$stats"
fi
