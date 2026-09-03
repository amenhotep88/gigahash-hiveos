#!/usr/bin/env bash
set -u

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash-amd}"
. "$CUSTOM_DIR/h-manifest.conf"
. "$CUSTOM_DIR/h-common.sh"

BIN="$CUSTOM_DIR/gigahash-zk-rocm10.0"
GH_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/gigahash-zk-rocm10.0-2.2.tar.gz.part-'
GH_PART_LAST=136
GH_ARCHIVE_SHA256='9c967a4f89e65d29b6d2fe4e36618506040dd548dc87260df9f1ef9992a9ba12'
EXPECTED_SHA256='a9bcf774b394956ef2eb0af15d9886e976abd5ab04c27d0eb5b990e9b7427019'
STATS_FILE="${CUSTOM_LOG_BASENAME}.json"

mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")"

verify_binary() {
  [[ -f "$BIN" ]] || return 1
  [[ "$(sha256sum "$BIN" 2>/dev/null | awk '{print $1}')" == "$EXPECTED_SHA256" ]]
}

download_binary() {
  local tmp_dir tmp_archive part part_index part_suffix candidate got
  tmp_dir="$(mktemp -d "$CUSTOM_DIR/.gigahash-amd-2.2.XXXXXX")" || return 1
  tmp_archive="$tmp_dir/gigahash-zk-rocm10.0-2.2.tar.gz"
  echo "[gigahash-hiveos] Downloading verified GigaHash ZK v2.2 ROCm mirror..."
  for part_index in $(seq 0 "$GH_PART_LAST"); do
    printf -v part_suffix '%03d' "$part_index"
    part="$tmp_dir/part-$part_suffix"
    if command -v curl >/dev/null 2>&1; then
      curl -fL --retry 3 --connect-timeout 15 -o "$part" "${GH_PART_BASE}${part_suffix}" || { rm -rf "$tmp_dir"; return 1; }
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$part" "${GH_PART_BASE}${part_suffix}" || { rm -rf "$tmp_dir"; return 1; }
    else
      echo "[gigahash-hiveos] ERROR: curl/wget not found" >&2
      rm -rf "$tmp_dir"
      return 1
    fi
    cat "$part" >> "$tmp_archive"
    rm -f "$part"
  done

  got="$(sha256sum "$tmp_archive" | awk '{print $1}')"
  [[ "$got" == "$GH_ARCHIVE_SHA256" ]] || { echo "[gigahash-hiveos] ERROR: archive SHA256 mismatch" >&2; rm -rf "$tmp_dir"; return 1; }
  tar -xzf "$tmp_archive" -C "$tmp_dir" gigahash-zk-rocm10.0/gigahash-zk-rocm10.0 || { rm -rf "$tmp_dir"; return 1; }
  candidate="$tmp_dir/gigahash-zk-rocm10.0/gigahash-zk-rocm10.0"
  got="$(sha256sum "$candidate" | awk '{print $1}')"
  [[ "$got" == "$EXPECTED_SHA256" ]] || { echo "[gigahash-hiveos] ERROR: binary SHA256 mismatch" >&2; rm -rf "$tmp_dir"; return 1; }
  mv -f "$candidate" "$BIN"
  chmod 755 "$BIN"
  rm -rf "$tmp_dir"
}

[[ -e /dev/kfd ]] || { echo "[gigahash-hiveos] ERROR: AMD KFD device is unavailable" >&2; exit 77; }
verify_binary || download_binary || exit 1

if [[ ! -s "$CUSTOM_CONFIG_FILENAME" ]]; then
  "$CUSTOM_DIR/h-config.sh" || exit 1
fi
. "$CUSTOM_CONFIG_FILENAME"

[[ -n "${GH_PAYOUT:-}" ]] || { echo "[gigahash-hiveos] ERROR: payout address is empty. Set Wallet and worker template to %WAL%." >&2; exit 2; }
extra_args=()
if [[ -n "${GH_EXTRA:-}" ]]; then read -r -a extra_args <<< "$GH_EXTRA"; fi

rm -f "$STATS_FILE"
run_with_log "${CUSTOM_LOG_BASENAME}.log" "$BIN" --server "$GH_SERVER" --payout-address "$GH_PAYOUT" --worker-name "$GH_WORKER" --stats-file "$STATS_FILE" "${extra_args[@]}"
exit $?
