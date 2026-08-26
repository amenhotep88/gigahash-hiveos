#!/usr/bin/env bash

normalize_payout() {
  local payout="$1"
  local worker="$2"
  local suffix=".${worker}"

  if [[ -n "$worker" && "$payout" == *"$suffix" ]]; then
    payout="${payout:0:${#payout}-${#suffix}}"
  fi
  printf '%s' "$payout"
}

run_with_log() {
  local log="$1"
  shift

  "$@" 2>&1 | tee -a "$log"
  return "${PIPESTATUS[0]}"
}
