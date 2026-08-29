#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "$3: missing '$2'"
}
assert_not_contains() {
  [[ "$1" != *"$2"* ]] || fail "$3: unexpectedly contains '$2'"
}
assert_eq() {
  [[ "$1" == "$2" ]] || fail "$3: expected '$2', got '$1'"
}

test_standard_package_defaults_to_ru1_and_v2_0() {
  local tmp custom config run_script
  tmp="$(mktemp -d)"
  custom="$tmp/gigahash"
  config="$custom/gigahash.conf"
  mkdir -p "$custom"
  cp "$REPO_DIR/h-common.sh" "$custom/h-common.sh"
  cat > "$custom/h-manifest.conf" <<EOF
CUSTOM_NAME=gigahash
CUSTOM_VERSION=2.0.0
CUSTOM_CONFIG_FILENAME=$config
CUSTOM_LOG_BASENAME=$tmp/gigahash
EOF

  CUSTOM_DIR="$custom" CUSTOM_TEMPLATE='W1NOCK' WORKER_NAME='testrig' \
    bash "$REPO_DIR/h-config.sh"
  # shellcheck disable=SC1090
  . "$config"
  assert_eq "$GH_SERVER" 'ru1.gigahash.cloud:9100' 'standard default server'

  run_script="$(cat "$REPO_DIR/h-run.sh")"
  assert_contains "$run_script" "GH_PART_BASE='https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/vendor/gigahash-zk-2.0.tar.gz.part-'" 'standard CDN part URL'
  assert_contains "$run_script" 'GH_PART_LAST=54' 'standard last archive part'
  assert_contains "$run_script" '6cb70e8d7d79b9d2b851b08d71059e94869a345918aa35dba908563e6268e7d0' 'standard archive SHA256'
  assert_contains "$run_script" 'ec6b9a9fed28b34c3d2b33bae381021d7ae4704f0bd295841cea6bd555f7a0a7' 'standard binary SHA256'
  assert_contains "$run_script" 'cat "$part" >> "$tmp_archive"' 'standard archive assembly'
  assert_not_contains "$run_script" 'cdn.gigahash.cloud' 'standard package direct CDN dependency'
  assert_not_contains "$run_script" '--low-cpu' 'standard package forced low-cpu mode'
  assert_contains "$(cat "$REPO_DIR/h-manifest.conf")" 'CUSTOM_VERSION=2.0.0' 'standard package version'
  assert_contains "$(cat "$REPO_DIR/build.sh")" "VERSION='2.0.0'" 'standard archive version'
  assert_contains "$(cat "$REPO_DIR/h-stats.sh")" '"2.0"' 'standard stats version'
  rm -rf "$tmp"
}

test_public_tree_has_no_internal_work_artifacts() {
  local hidden_dir prompt_file forbidden_re matches
  hidden_dir="$(printf '%s' 'LmNvZGV4' | base64 -d)"
  prompt_file="$(printf '%s' 'UjdfV09SS19TVEFSVF9QUk9NUFRfMjAyNi0wOC0yOS5tZA==' | base64 -d)"
  forbidden_re="$(printf '%s' 'Y29kZXh8Y2hhdGdwdHxvcGVuYWl8XGJsbG1cYnxcYmFpXGJ8UjdfV09SS19TVEFSVF9QUk9NUFQ=' | base64 -d)"

  [[ ! -e "$REPO_DIR/$hidden_dir" ]] || fail 'internal hidden directory must not be published'
  [[ ! -e "$REPO_DIR/$prompt_file" ]] || fail 'internal work-start file must not be published'
  matches="$(rg -n -i "$forbidden_re" \
    --glob '!vendor/**' --glob '!*.tar.gz' --glob '!.git/**' \
    "$REPO_DIR" || true)"
  [[ -z "$matches" ]] || fail "internal work references remain: $matches"
}

test_retired_split_is_absent() {
  [[ ! -e "$REPO_DIR/build-split.sh" ]] || fail 'retired split build script still exists'
  [[ ! -e "$REPO_DIR/split" ]] || fail 'retired split source directory still exists'
  [[ ! -e "$REPO_DIR/tests/test_split_wrapper.sh" ]] || fail 'retired split test still exists'

  if compgen -G "$REPO_DIR/gigahash-prl-split-*.tar.gz" >/dev/null; then
    fail 'retired split package still exists'
  fi
  if compgen -G "$REPO_DIR/vendor/srbminer_custom-*" >/dev/null; then
    fail 'retired SRBMiner vendor archive still exists'
  fi
}

test_standard_package_defaults_to_ru1_and_v2_0
test_retired_split_is_absent
test_public_tree_has_no_internal_work_artifacts
echo 'PASS: GigaHash v2.0 release configuration'
