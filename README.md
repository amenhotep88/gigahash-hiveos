# GigaHash ZK v2.4 — HiveOS Custom Miner 2.4.0

Unofficial HiveOS wrapper for the official `gigahash.cloud` NOCK ZK CUDA miner.
The proprietary miner binary is **not bundled**. On first start, the wrapper reconstructs a mirror archive built from the official v2.4 binary and verifies both the archive and binary SHA-256 checksums.

## Flight Sheet

- Miner: **Custom**
- Installation URL: `https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-2.4.0.tar.gz`
- Hash algorithm: leave blank / `----`
- Wallet and worker template: **`%WAL%`**
- Pool URL: `backup.gigahash.cloud:9100`
- Pass: blank
- Extra Config Arguments: optional native GigaHash CLI args, e.g. `--low-cpu` or `--devices 0,1,2,3,4,5`

The HiveOS rig name is passed automatically as `--worker-name`. Use `%WAL%` only;
the wrapper also strips a matching `.worker-name` suffix defensively when HiveOS adds one.

## Stats

HiveOS displays GigaHash proof rate using its generic hash-rate fields:
- `1 proof/s` is represented as `1 H/s`
- `23.5 kp/s` is therefore shown as approximately `23.5 kH/s`

Per-GPU proof rate, temperature and fan are read from the native JSON stats file added by GigaHash, with console-table parsing retained as a fallback.
The local GigaHash `Accepted` counter is deliberately not exported because it can stay at zero even while the pool account page reports valid accepted shares.
Miner output is mirrored to both the `miner` console and the log used by HiveOS stats.

## Official miner pinned by this package

- GigaHash ZK: v2.4
- CUDA build: 12.9
- URL: `https://cdn.gigahash.cloud/releases/2.4/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9`
- SHA256: `372fb8fbe72c4a493016dc8d1fa6f54e2a16ae028bb32ca7f8fa02c62d6f660a`
- HiveOS package SHA256: `8557335689e34ff69a96e38e1d9c6813639175603a25c5ff197770da8587424a`

## Verified v2.4 interface

- accepts comma-separated primary and backup pool endpoints;
- retains `--backup-server`, `--low-cpu`, `--devices`, and native JSON stats support;
- reports `gigahash-zk 2.4` through `--version`.

The v2.4 binary, command-line interface, and checksum were verified
directly from the GigaHash CDN before this wrapper was built. Low-CPU mode and
additional endpoint overrides are enabled only when explicitly supplied through
Extra Config Arguments.

The previous NVIDIA v2.3 package and its GitHub release remain available for rollback.

## AMD HiveOS package

The repository also contains a separate AMD package for the official GigaHash
ZK v2.5 AMD binary:

- Custom miner name: `gigahash-amd`
- Package: `gigahash-amd-2.5.0.tar.gz`
- Package version: `2.5.0-amd1`
- Installation URL: `https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-amd-2.5.0.tar.gz`
- Supported family declared by the release: AMD RDNA2/RDNA3/RDNA4
- Official archive: `https://cdn.gigahash.cloud/releases/2.5/hiveos/gigahash-zk-amd-2.5.tar.gz`
- Official archive SHA-256: `529abd01baf0eaf73ea420fcb373739680c0d6a2a42210f959dab4676b43b4e5`
- Official binary: `gigahash-zk-amd`
- Official binary SHA-256: `1e10d5793aa70fdf6f52666e06e264f7079eb91bdb1f4073223777e54db1612b`
- Package SHA-256: `c6497a2f9a5200a4b064845faff6d3debe6a1428cbc02c876bcfa5d4493db90b`

The previous AMD v2.4 and v2.2 packages and releases remain available for rollback.

The NVIDIA and AMD packages use distinct HiveOS directories, manifests, logs,
process names, mirror archives, tests, and release workflows. Do not mix their
files in one Custom Miner installation.

## Notes

The default endpoint is `backup.gigahash.cloud:9100`, selected as the operational
default after pool connectivity issues.

## Operations and handoff

- [Current Russian handoff](docs/HANDOFF_CURRENT_2026-09-04_RU.md)
- [Pool, profitability, and Clore rental runbook](docs/POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md)
- [Local NoSSD to GigaHash migration and rollback](docs/NOSSD_TO_GIGAHASH_2026-09-04_RU.md)
- [HiveOS wrapper development](docs/HIVEOS_MINER_DEVELOPMENT.md)
- [GitHub release runbook](docs/GITHUB_RELEASE_RUNBOOK.md)
