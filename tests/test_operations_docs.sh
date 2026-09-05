#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
require_file() { [[ -f "$REPO_DIR/$1" ]] || fail "missing $1"; }
require_text() {
  grep -Fq -- "$2" "$REPO_DIR/$1" || fail "$1 missing: $2"
}

require_file docs/HANDOFF_CURRENT_2026-09-04_RU.md
require_file docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md
require_file docs/NOSSD_TO_GIGAHASH_2026-09-04_RU.md
require_file .codex/skills/gigahash-mining-operations/SKILL.md
require_file .codex/skills/gigahash-mining-operations/references/pool-profitability.md
require_file .codex/skills/gigahash-mining-operations/references/clore-rentals.md
require_file .codex/skills/gigahash-mining-operations/references/server-operations.md

for doc in \
  docs/HANDOFF_CURRENT_2026-09-04_RU.md \
  docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md \
  .codex/skills/gigahash-mining-operations/references/pool-profitability.md; do
  require_text "$doc" 'W1ijDJZsLuKiLpKWzr5LYeVMnJKF8Khx9stXEBoXQfxwjEotbxppbN'
done

require_text docs/HANDOFF_CURRENT_2026-09-04_RU.md 'gigahash-amd-2.2.0.tar.gz'
require_text docs/HANDOFF_CURRENT_2026-09-04_RU.md 'rz2-3080'
require_text docs/HANDOFF_CURRENT_2026-09-04_RU.md 'rzserv-3080'
require_text docs/HANDOFF_CURRENT_2026-09-04_RU.md 'x99-3070'
require_text docs/NOSSD_TO_GIGAHASH_2026-09-04_RU.md '/root/root.crontab.before-gigahash'
require_text docs/NOSSD_TO_GIGAHASH_2026-09-04_RU.md 'nossd-disks.timer'
require_text docs/NOSSD_TO_GIGAHASH_2026-09-04_RU.md 'nossd-vpn-subscription-update.timer'
require_text docs/NOSSD_TO_GIGAHASH_2026-09-04_RU.md 'sudo crontab /root/root.crontab.before-gigahash'
require_text .codex/skills/gigahash-mining-operations/references/clore-rentals.md '114377'
require_text .codex/skills/gigahash-mining-operations/SKILL.md 'gigahash-amd'
require_text .codex/skills/gigahash-mining-operations/SKILL.md 'GPU-loss watchdog'
require_text .codex/skills/gigahash-mining-operations/references/server-operations.md 'gigahash-watchdog'
require_text .codex/skills/gigahash-mining-operations/references/server-operations.md 'sleep 600'
require_text docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md 'restart_limit=2_per_hour'
require_text docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md 'cron может отсутствовать'
require_text .codex/skills/gigahash-mining-operations/references/server-operations.md 'aria2c interprets multiple positional URLs as mirrors'
require_text .codex/skills/gigahash-mining-operations/references/server-operations.md 'part-000 through part-054'
require_text docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md 'одного файла-задания'
require_text docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md '7bc5f839561434a2145b861517c4fcbb6dea0aa8ea03a53398dc2bdccb4bd959'

echo 'PASS: operational handoff and skill invariants'
