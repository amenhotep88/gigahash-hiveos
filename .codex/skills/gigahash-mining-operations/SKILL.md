---
name: gigahash-mining-operations
description: Use when operating GigaHash NOCK ZK miners, analyzing the user's pool payout account, calculating mining or Clore rental profitability, selecting rental servers, packaging the HiveOS wrapper, publishing releases, or switching local NoSSD servers to and from GigaHash.
---

# GigaHash mining operations

Use the repository handoff as the authoritative project state. Preserve measured facts separately from estimates and never infer a concrete server's hashrate solely from its GPU model.

## Route the task

- For pool workers, payouts, balance, NOCK/day, network/pool difficulty or price inputs, read `references/pool-profitability.md`, `references/live-data-sources.md` and `../../../docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md`.
- For Clore search, ranking, stop-list or rental validation, read `references/clore-rentals.md` and the profitability runbook.
- For any hashrate estimate, GPU comparison or candidate ranking, also read `references/historical-hashrates.md`. Never apply a blanket performance uplift to an untested GPU family.
- For Ubuntu/Clore installation, systemd/Supervisor, NoSSD migration or rollback, read `references/server-operations.md` and `../../../docs/NOSSD_TO_GIGAHASH_2026-09-04_RU.md`.
- For NVIDIA or AMD/ROCm HiveOS wrapper changes, read `../../../docs/HIVEOS_MINER_DEVELOPMENT.md` completely and keep the two packages isolated.
- For GitHub publication, read `../../../docs/GITHUB_RELEASE_RUNBOOK.md` completely and inspect `git status` before staging.

## Invariants

1. Pool-side accounting is authoritative for credited shares, balances and payouts; local `Accepted` is a health signal.
2. Update live NOCK price, pool yield and rental availability before financial conclusions.
3. Separate owned workers from `clore-*` and reconcile active Clore orders against live pool workers.
4. Check actual `nvidia-smi` PL/clocks/VRAM after renting; listing PL is not proof.
5. Exclude US and the documented stop-list from candidate output.
6. On Clore use Supervisor. On full Ubuntu use systemd.
7. NoSSD has independent cron and disk-timer watchdogs; disabling `miner.service` alone is unsafe.
8. Do not raise PL or invent clock locks without an explicit request and a baseline for that exact GPU.
9. Stage and commit only task-owned files; preserve dirty user work.
10. Treat `gigahash` (CUDA) and `gigahash-amd` (ROCm) as separate packages, binaries, hashes, mirrors, tests, tags and releases.
11. For multi-GPU Clore rigs, install the documented Supervisor-managed GPU-loss watchdog after the miner is stable. Do not assume cron exists.
12. Use GigaHash NVIDIA v2.3 by default. Use another version only for an explicit compatibility test or rollback.
13. Search the whole Clore API first. Use the authenticated CometFox browser only for pool/account verification, current order confirmation or fields unavailable from the API.
14. Searching and reporting do not authorize renting, changing an order, starting a remote install or deleting data. Obtain explicit authorization immediately before the external mutation.
15. Treat pool hashrate, network hashrate/difficulty and coin price as separate inputs. Report the endpoint, timestamp and units for each; never infer network growth from pool worker count alone.
16. Use only the exact GigaHash API routes and retry procedure in `references/live-data-sources.md`. Do not guess API variants. Use CometFox only after the deterministic API retry fails, and label browser-derived values.
17. A ticker bid is not automatically executable. Verify order-book depth, account access, deposit status, payout/deposit network compatibility and all conversion costs before using another exchange for rental approval.
18. Reconcile connected worker count and hashrate against enumerated fresh workers, then reconcile every active Clore order against its pool worker. Pool-offline alone does not prove that an order ended.

Return concise tables with assumptions, observed facts, thresholds and a clear keep/cancel or proceed/stop decision.
