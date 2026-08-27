#!/usr/bin/env bash
set -u

CUSTOM_DIR="${CUSTOM_DIR:-/hive/miners/custom/gigahash-prl-split}"
. "$CUSTOM_DIR/h-manifest.conf"
. "$CUSTOM_DIR/h-common.sh"

GH_BIN="$CUSTOM_DIR/gigahash-zk-12.9"
GH_URL='https://cdn.gigahash.cloud/releases/1.8/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9'
GH_SHA256='bd0c9ca5b626fceb1e7c71cb852073a1b4c30cdc6477925947e589d27b19139c'
SRB_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/srbminer_custom-3.6.0.tar.gz.part-'
SRB_PART_LAST=26
SRB_SHA256='9908635af2a12f925d92f6d15e79f2f8df4b57070e478bd1c7e30d282ee10fb3'
SRB_VENDOR_DIR="$CUSTOM_DIR/vendor/srbminer-3.6.0"
GH_STATS="${CUSTOM_LOG_BASENAME}-nock.json"
GH_LOG="${CUSTOM_LOG_BASENAME}-nock.log"
PRL_LOG="${CUSTOM_LOG_BASENAME}-prl.log"

mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")" "$CUSTOM_DIR/vendor"

install_gh() {
  verify_sha256 "$GH_BIN" "$GH_SHA256" && return 0
  local tmp="${GH_BIN}.download.$$"
  echo '[split] Downloading official GigaHash ZK v1.8...'
  rm -f "$tmp"
  download_file "$GH_URL" "$tmp" || return 1
  if ! verify_sha256 "$tmp" "$GH_SHA256"; then
    echo '[split] ERROR: GigaHash SHA256 mismatch' >&2
    rm -f "$tmp"
    return 1
  fi
  mv -f "$tmp" "$GH_BIN"
  chmod 755 "$GH_BIN"
}

install_srb() {
  local archive tmp_archive tmp_extract candidate part part_index part_suffix
  archive="$CUSTOM_DIR/vendor/srbminer_custom-3.6.0.tar.gz"
  tmp_archive="${archive}.download.$$"
  tmp_extract="$CUSTOM_DIR/vendor/.srbminer-3.6.0.$$"

  if [[ ! -f "$archive" ]] || ! verify_sha256 "$archive" "$SRB_SHA256"; then
    echo '[split] Downloading verified SRBMiner-MULTI v3.6.0 mirror...'
    rm -f "$archive" "$tmp_archive" "${tmp_archive}.part-"*
    for part_index in $(seq 0 "$SRB_PART_LAST"); do
      printf -v part_suffix '%02d' "$part_index"
      part="${tmp_archive}.part-${part_suffix}"
      if ! download_file "${SRB_PART_BASE}${part_suffix}" "$part"; then
        rm -f "$tmp_archive" "${tmp_archive}.part-"*
        return 1
      fi
      cat "$part" >> "$tmp_archive"
      rm -f "$part"
    done
    mv -f "$tmp_archive" "$archive"
  fi
  if ! verify_sha256 "$archive" "$SRB_SHA256"; then
    echo '[split] ERROR: SRBMiner SHA256 mismatch' >&2
    rm -f "$archive"
    return 1
  fi

  rm -rf "$tmp_extract"
  mkdir -p "$tmp_extract"
  tar -xzf "$archive" -C "$tmp_extract" || return 1
  candidate="$(find_srb_binary "$tmp_extract")"
  if [[ -z "$candidate" ]]; then
    echo '[split] ERROR: SRBMiner-MULTI not found in official archive' >&2
    rm -rf "$tmp_extract"
    return 1
  fi
  rm -rf "$SRB_VENDOR_DIR"
  mv "$tmp_extract" "$SRB_VENDOR_DIR"
}

resolve_srb_binary() {
  local candidate=''
  if [[ -n "${SRB_BIN_OVERRIDE:-}" && -x "$SRB_BIN_OVERRIDE" ]]; then
    printf '%s' "$SRB_BIN_OVERRIDE"
    return 0
  fi

  candidate="$(find_srb_binary "$SRB_VENDOR_DIR")"
  if [[ -n "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi

  # Reuse an already installed official SRBMiner custom package. This also
  # avoids a second GitHub release download on rigs where it is present.
  candidate="$(find_srb_binary /hive/miners/custom/srbminer_custom)"
  if [[ -n "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi

  install_srb || return 1
  candidate="$(find_srb_binary "$SRB_VENDOR_DIR")"
  [[ -n "$candidate" ]] || return 1
  printf '%s' "$candidate"
}

install_gh || exit 1

if [[ ! -s "$CUSTOM_CONFIG_FILENAME" ]]; then
  "$CUSTOM_DIR/h-config.sh" || exit 1
fi
. "$CUSTOM_CONFIG_FILENAME"

if [[ -z "${GH_PAYOUT:-}" ]]; then
  echo '[split] ERROR: NOCK payout is empty. Use the NOCK wallet and %WAL% template.' >&2
  exit 2
fi

SRB_BIN="$(resolve_srb_binary)" || {
  echo '[split] ERROR: unable to install or locate SRBMiner-MULTI' >&2
  exit 3
}
SRB_WORKDIR="$(dirname "$SRB_BIN")"

rm -f "$GH_STATS"
: > "$GH_LOG"
: > "$PRL_LOG"

gh_pid=''
prl_pid=''
tail_pid=''

cleanup() {
  trap - EXIT INT TERM
  local pid
  for pid in "$gh_pid" "$prl_pid" "$tail_pid"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
    fi
  done
  for pid in "$gh_pid" "$prl_pid" "$tail_pid"; do
    [[ -n "$pid" ]] && wait "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

echo "[split] NOCK GPU: $GH_DEVICES | PRL GPU: $PRL_DEVICES"

"$GH_BIN" \
  --server "$GH_SERVER" \
  --payout-address "$GH_PAYOUT" \
  --worker-name "$GH_WORKER" \
  --stats-file "$GH_STATS" \
  --instances "$GH_INSTANCES" \
  --devices "$GH_DEVICES" \
  >> "$GH_LOG" 2>&1 &
gh_pid=$!

(
  cd "$SRB_WORKDIR" || exit 1
  exec "$SRB_BIN" \
    --algorithm-gpu pearlhash \
    --wallet "$PRL_WALLET" \
    --worker "$PRL_WORKER" \
    --pool "$PRL_POOL" \
    --gpu-id "$PRL_DEVICES" \
    --disable-cpu \
    --api-enable \
    --api-port 21550
) >> "$PRL_LOG" 2>&1 &
prl_pid=$!

tail -n +1 -F "$GH_LOG" "$PRL_LOG" &
tail_pid=$!

wait -n "$gh_pid" "$prl_pid"
rc=$?
if ! kill -0 "$gh_pid" 2>/dev/null; then
  echo "[split] GigaHash exited with status $rc"
else
  echo "[split] SRBMiner exited with status $rc"
fi
exit "$rc"
