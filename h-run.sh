#!/usr/bin/env bash
set -u

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash}"
. "$CUSTOM_DIR/h-manifest.conf"
. "$CUSTOM_DIR/h-common.sh"

BIN="$CUSTOM_DIR/gigahash-zk-12.9"
DOWNLOAD_URL="https://cdn.gigahash.cloud/releases/1.8/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9"
EXPECTED_SHA256="bd0c9ca5b626fceb1e7c71cb852073a1b4c30cdc6477925947e589d27b19139c"
STATS_FILE="${CUSTOM_LOG_BASENAME}.json"

mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")"

verify_binary() {
  [[ -f "$BIN" ]] || return 1
  local got
  got="$(sha256sum "$BIN" 2>/dev/null | awk '{print $1}')"
  [[ "$got" == "$EXPECTED_SHA256" ]]
}

download_binary() {
  local tmp="${BIN}.download.$$"
  rm -f "$tmp"
  echo "[gigahash-hiveos] Downloading official GigaHash ZK v1.8..."
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --connect-timeout 15 -o "$tmp" "$DOWNLOAD_URL" || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$tmp" "$DOWNLOAD_URL" || return 1
  else
    echo "[gigahash-hiveos] ERROR: curl/wget not found" >&2
    return 1
  fi

  local got
  got="$(sha256sum "$tmp" | awk '{print $1}')"
  if [[ "$got" != "$EXPECTED_SHA256" ]]; then
    echo "[gigahash-hiveos] ERROR: SHA256 mismatch" >&2
    echo "[gigahash-hiveos] expected: $EXPECTED_SHA256" >&2
    echo "[gigahash-hiveos] got:      $got" >&2
    rm -f "$tmp"
    return 1
  fi

  mv -f "$tmp" "$BIN"
  chmod 755 "$BIN"
}

if ! verify_binary; then
  download_binary || exit 1
fi

# h-config.sh is called by Hive before h-run.sh, but allow manual diagnostics too.
if [[ ! -s "$CUSTOM_CONFIG_FILENAME" ]]; then
  "$CUSTOM_DIR/h-config.sh" || exit 1
fi
. "$CUSTOM_CONFIG_FILENAME"

if [[ -z "${GH_PAYOUT:-}" ]]; then
  echo "[gigahash-hiveos] ERROR: payout address is empty. Set Wallet and worker template to %WAL%." >&2
  exit 2
fi

extra_args=()
if [[ -n "${GH_EXTRA:-}" ]]; then
  # Intentionally no eval: whitespace-separated CLI args only.
  read -r -a extra_args <<< "$GH_EXTRA"
fi

rm -f "$STATS_FILE"
run_with_log "${CUSTOM_LOG_BASENAME}.log" "$BIN" \
  --server "$GH_SERVER" \
  --payout-address "$GH_PAYOUT" \
  --worker-name "$GH_WORKER" \
  --stats-file "$STATS_FILE" \
  "${extra_args[@]}"
exit $?
