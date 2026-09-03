#!/usr/bin/env bash
set -u

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash}"
. "$CUSTOM_DIR/h-manifest.conf"
. "$CUSTOM_DIR/h-common.sh"

BIN="$CUSTOM_DIR/gigahash-zk-12.9"
GH_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/gigahash-zk-2.2.tar.gz.part-'
GH_PART_LAST=54
GH_ARCHIVE_SHA256='7bc5f839561434a2145b861517c4fcbb6dea0aa8ea03a53398dc2bdccb4bd959'
EXPECTED_SHA256='72cacd1f5a23fa4a983f56f0df5eaf9876ebb38a19ca637b94e5c0816e6ec5af'
STATS_FILE="${CUSTOM_LOG_BASENAME}.json"

mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")"

verify_binary() {
  [[ -f "$BIN" ]] || return 1
  local got
  got="$(sha256sum "$BIN" 2>/dev/null | awk '{print $1}')"
  [[ "$got" == "$EXPECTED_SHA256" ]]
}

download_binary() {
  local tmp_dir tmp_archive part part_index part_suffix candidate got
  tmp_dir="$(mktemp -d "$CUSTOM_DIR/.gigahash-2.2.XXXXXX")" || return 1
  tmp_archive="$tmp_dir/gigahash-zk-2.2.tar.gz"
  echo "[gigahash-hiveos] Downloading verified GigaHash ZK v2.2 mirror..."
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
  if [[ "$got" != "$GH_ARCHIVE_SHA256" ]]; then
    echo "[gigahash-hiveos] ERROR: archive SHA256 mismatch" >&2
    rm -rf "$tmp_dir"
    return 1
  fi
  tar -xzf "$tmp_archive" -C "$tmp_dir" gigahash-zk/gigahash-zk || { rm -rf "$tmp_dir"; return 1; }
  candidate="$tmp_dir/gigahash-zk/gigahash-zk"
  got="$(sha256sum "$candidate" | awk '{print $1}')"
  if [[ "$got" != "$EXPECTED_SHA256" ]]; then
    echo "[gigahash-hiveos] ERROR: binary SHA256 mismatch" >&2
    rm -rf "$tmp_dir"
    return 1
  fi
  mv -f "$candidate" "$BIN"
  chmod 755 "$BIN"
  rm -rf "$tmp_dir"
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
