#!/usr/bin/env bash

normalize_payout() {
  local payout="${1:-}" worker="${2:-}"
  payout="$(printf '%s' "$payout" | tr -d '\r\n[:space:]')"
  if [[ -n "$worker" && "$payout" == *".$worker" ]]; then
    payout="${payout%.$worker}"
  fi
  printf '%s' "$payout"
}

download_file() {
  local url="$1" destination="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --connect-timeout 15 -o "$destination" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$destination" "$url"
  else
    echo '[split] ERROR: curl/wget not found' >&2
    return 1
  fi
}

verify_sha256() {
  local file="$1" expected="$2" got
  [[ -f "$file" ]] || return 1
  got="$(sha256sum "$file" 2>/dev/null | awk '{print $1}')"
  [[ "$got" == "$expected" ]]
}

find_srb_binary() {
  local base="$1"
  find "$base" -type f -name 'SRBMiner-MULTI' -perm /111 2>/dev/null | head -n 1
}
