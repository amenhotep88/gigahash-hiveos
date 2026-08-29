---
name: gigahash-hiveos-development
description: Use when updating, diagnosing, testing, or explaining the amenhotep88/gigahash-hiveos wrapper, GigaHash ZK binaries, HiveOS Custom Miner scripts, pool statistics, GPU behavior, mirror parts, or miner version upgrades.
---

# GigaHash HiveOS Development

## Overview

Treat this as a HiveOS wrapper around a proprietary official GigaHash ZK binary. Change shell integration, verified delivery, stats, packaging, and release metadata; never claim to modify the CUDA miner itself.

## Start every project task

1. Read `R7_WORK_START_PROMPT_2026-08-29.md` and `docs/HANDOFF_CURRENT_2026-08-29.md`.
2. Read `docs/HIVEOS_MINER_DEVELOPMENT.md` for code or runtime work.
3. Run `git status --short --branch` and inspect recent commits before editing.
4. Preserve unrelated user changes. Do not push or change live rigs unless the user explicitly requests it.

## Current boundaries

- The only active product is the standard GigaHash ZK wrapper, currently binary v1.9/package 1.9.0.
- Split, PRL, PearlHash, and SRBMiner are discontinued. Do not recreate them unless the user explicitly reverses that decision.
- One GigaHash OS process serves all selected GPUs. `--instances 2` means internal GPU instances, not two processes.
- Keep `--low-cpu` optional. Do not force experimental flags from the wrapper.
- Pool API balances use `65,536 nicks = 1 NOCK`.

## Choose the workflow

| Request | Action |
|---|---|
| Diagnose a rig | Collect read-only process, log, GPU, pool, Xid/OOM evidence; change one variable per test |
| Fix wrapper behavior | Reproduce with a shell test, patch the smallest wrapper surface, rerun all tests |
| Upgrade official binary | Read [references/version-upgrade.md](references/version-upgrade.md) and the GitHub release skill |
| Estimate earnings | Use credited pool balances/payout timestamps; separate actual accrual from instantaneous calculator output |
| Suggest miner optimization | Report controlled measurements and hypotheses to the official developer; do not imply wrapper access to CUDA internals |

For rig interaction, give one command at a time and wait for its full output.

## Completion gate

Run fresh:

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
./build.sh
sha256sum gigahash-1.9.0.tar.gz
tar -tzf gigahash-1.9.0.tar.gz
git diff --check
```

Also scan the current tree for forbidden split/PRL/SRB references. Report exact evidence and any remaining uncertainty.

## Common mistakes

- Dividing nicks by 100,000 instead of 65,536.
- Treating local `Accepted` as the credited pool counter.
- Changing OC, binary version, server, and flags in one test.
- Assuming low average PCIe throughput proves linear spare hashrate.
- Publishing a package after changing only some version/hash constants.
