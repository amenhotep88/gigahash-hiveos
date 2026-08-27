#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPLIT_DIR="$REPO_DIR/split/gigahash-prl-split"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local got="$1" expected="$2" label="$3"
  [[ "$got" == "$expected" ]] || fail "$label: expected '$expected', got '$got'"
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$label: missing '$needle' in '$haystack'"
}

test_config_generates_fixed_redrig_split() {
  local tmp custom config
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash-prl-split"
  config="$custom/gigahash-prl-split.conf"
  mkdir -p "$custom"
  cp "$SPLIT_DIR/h-common.sh" "$custom/h-common.sh"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash-prl-split
CUSTOM_VERSION=1.0.0
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash-prl-split
EOF

  CUSTOM_DIR="$custom" \
  CUSTOM_URL='84.32.220.164:9100' \
  CUSTOM_TEMPLATE='W1NOCK.redrig' \
  WORKER_NAME='redrig' \
    bash "$SPLIT_DIR/h-config.sh"

  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" '84.32.220.164:9100' 'NOCK server'
  assert_eq "$GH_PAYOUT" 'W1NOCK' 'NOCK payout normalization'
  assert_eq "$GH_DEVICES" '0,1,2,3' 'NOCK GPU split'
  assert_eq "$GH_INSTANCES" '2' 'NOCK instances'
  assert_eq "$PRL_POOL" 'prl-ru.kryptex.network:7048' 'PRL pool'
  assert_eq "$PRL_WALLET" 'prl1pq2g5uzwq8uth2l6f5tzw0v85re5qmatw5y9uqy38pmfz2dnlvkhseq95q9' 'PRL wallet'
  assert_eq "$PRL_DEVICES" '4,5,6,7' 'PRL GPU split'
  rm -rf "$tmp"
}

test_run_starts_both_miners_on_disjoint_gpus_and_stops_peer() {
  local tmp custom fake_path output rc gh_args prl_args
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash-prl-split"
  fake_path="$tmp/bin"
  mkdir -p "$custom" "$fake_path"
  cp "$SPLIT_DIR/h-common.sh" "$custom/h-common.sh"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash-prl-split
CUSTOM_VERSION=1.0.0
CUSTOM_CONFIG_FILENAME=$custom/gigahash-prl-split.conf
CUSTOM_LOG_BASENAME=$tmp/gigahash-prl-split
EOF

  cat > "$custom/gigahash-prl-split.conf" <<'EOF'
GH_SERVER=84.32.220.164:9100
GH_PAYOUT=W1NOCK
GH_WORKER=redrig-NOCK
GH_DEVICES=0,1,2,3
GH_INSTANCES=2
PRL_POOL=prl-ru.kryptex.network:7048
PRL_WALLET=prl1pq2g5uzwq8uth2l6f5tzw0v85re5qmatw5y9uqy38pmfz2dnlvkhseq95q9
PRL_WORKER=redrig-PRL
PRL_DEVICES=4,5,6,7
EOF

  cat > "$custom/gigahash-zk-12.9" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$GH_ARGS_FILE"
sleep 0.2
exit 7
EOF
  chmod 755 "$custom/gigahash-zk-12.9"

  cat > "$custom/SRBMiner-MULTI" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$PRL_ARGS_FILE"
trap 'echo stopped > "$PRL_STOP_FILE"; exit 0' TERM INT
while :; do sleep 1; done
EOF
  chmod 755 "$custom/SRBMiner-MULTI"

  cat > "$fake_path/sha256sum" <<'EOF'
#!/usr/bin/env bash
echo 'b1f8c91172dc5f84fc7648ae9119b525efbc4d6953e267549bad4a4d17617ea1  placeholder'
EOF
  chmod 755 "$fake_path/sha256sum"

  set +e
  output="$(
    CUSTOM_DIR="$custom" \
    GH_ARGS_FILE="$tmp/gh.args" \
    PRL_ARGS_FILE="$tmp/prl.args" \
    PRL_STOP_FILE="$tmp/prl.stopped" \
    SRB_BIN_OVERRIDE="$custom/SRBMiner-MULTI" \
    PATH="$fake_path:$PATH" \
      timeout 8 bash "$SPLIT_DIR/h-run.sh" 2>&1
  )"
  rc=$?
  set -e

  [[ -s "$tmp/gh.args" ]] || fail 'GigaHash was not started'
  [[ -s "$tmp/prl.args" ]] || fail 'SRBMiner was not started'
  gh_args="$(cat "$tmp/gh.args")"
  prl_args="$(cat "$tmp/prl.args")"

  assert_eq "$rc" '7' 'combined wrapper exit status'
  assert_contains "$gh_args" '--server 84.32.220.164:9100' 'GigaHash server args'
  assert_contains "$gh_args" '--instances 2' 'GigaHash instances args'
  assert_contains "$gh_args" '--devices 0,1,2,3' 'GigaHash device args'
  assert_contains "$prl_args" '--algorithm-gpu pearlhash' 'SRBMiner algorithm args'
  assert_contains "$prl_args" '--pool prl-ru.kryptex.network:7048' 'SRBMiner pool args'
  assert_contains "$prl_args" '--gpu-id 4,5,6,7' 'SRBMiner device args'
  assert_contains "$prl_args" '--disable-cpu' 'SRBMiner CPU exclusion'
  assert_contains "$prl_args" '--api-enable --api-port 21550' 'SRBMiner API args'
  [[ -s "$tmp/prl.stopped" ]] || fail 'SRBMiner peer was not stopped after GigaHash exit'
  [[ "$output" == *'[split] GigaHash exited with status 7'* ]] || fail 'exit reason is not reported'
  rm -rf "$tmp"
}

test_stats_exports_only_nock_rate() {
  local tmp custom output
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash-prl-split"
  mkdir -p "$custom" "$tmp/log"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash-prl-split
CUSTOM_VERSION=1.0.0
CUSTOM_CONFIG_FILENAME=$custom/gigahash-prl-split.conf
CUSTOM_LOG_BASENAME=$tmp/log/gigahash-prl-split
EOF
  cat > "$tmp/log/gigahash-prl-split-nock.json" <<'EOF'
{"hashrate":14560,"uptime_seconds":300,"miner_version":"1.7","gpus":[{"hashrate":3670,"temperature_celsius":54,"fan_percent":43},{"hashrate":3670,"temperature_celsius":57,"fan_percent":30},{"hashrate":3600,"temperature_celsius":58,"fan_percent":30},{"hashrate":3620,"temperature_celsius":56,"fan_percent":32}]}
EOF

  output="$(CUSTOM_DIR="$custom" bash "$SPLIT_DIR/h-stats.sh")"
  assert_contains "$output" 'khs=14.56' 'NOCK total stats'
  assert_contains "$output" '"hs":[3.67,3.67,3.6,3.62]' 'NOCK per-GPU stats'
  assert_contains "$output" '"algo":"nock-zk"' 'NOCK stats algorithm'
  rm -rf "$tmp"
}

test_srb_download_uses_rig_accessible_cdn_parts() {
  local run_script
  run_script="$(cat "$SPLIT_DIR/h-run.sh")"
  assert_contains "$run_script" \
    "SRB_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/srbminer_custom-3.6.0.tar.gz.part-'" \
    'SRBMiner CDN part URL'
  assert_contains "$run_script" "SRB_PART_LAST=26" 'SRBMiner last archive part'
  assert_contains "$run_script" 'cat "$part" >> "$tmp_archive"' 'SRBMiner archive assembly'
  [[ "$run_script" != *'github.com/doktor83/SRBMiner-Multi/releases/download/'* ]] || \
    fail 'SRBMiner still depends on blocked GitHub release assets'
}

test_split_package_version_is_1_0_1() {
  assert_contains "$(cat "$SPLIT_DIR/h-manifest.conf")" 'CUSTOM_VERSION=1.0.1' 'split manifest version'
  assert_contains "$(cat "$REPO_DIR/build-split.sh")" "VERSION='1.0.1'" 'split archive version'
  assert_contains "$(cat "$SPLIT_DIR/h-stats.sh")" 'split-1.0.1/gh-' 'split stats version'
}

test_config_generates_fixed_redrig_split
test_run_starts_both_miners_on_disjoint_gpus_and_stops_peer
test_stats_exports_only_nock_rate
test_srb_download_uses_rig_accessible_cdn_parts
test_split_package_version_is_1_0_1
echo 'PASS: split wrapper behavior'
