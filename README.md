# GigaHash ZK v2.2 — HiveOS Custom Miner 2.2.0

Unofficial HiveOS wrapper for the official `gigahash.cloud` NOCK ZK CUDA miner.
The proprietary miner binary is **not bundled**. On first start, the wrapper reconstructs a mirror archive built from the official v2.2 binary and verifies both the archive and binary SHA-256 checksums.

## Flight Sheet

- Miner: **Custom**
- Installation URL: `https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-2.2.0.tar.gz`
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

- GigaHash ZK: v2.2
- CUDA build: 12.9
- URL: `https://cdn.gigahash.cloud/releases/2.2/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9`
- SHA256: `72cacd1f5a23fa4a983f56f0df5eaf9876ebb38a19ca637b94e5c0816e6ec5af`

## Verified v2.2 interface

- accepts comma-separated primary and backup pool endpoints;
- retains `--backup-server`, `--low-cpu`, `--devices`, and native JSON stats support;
- reports `gigahash-zk 2.2` through `--version`.

The v2.2 binary, command-line interface, and checksum were verified
directly from the GigaHash CDN before this wrapper was built. Low-CPU mode and
additional endpoint overrides are enabled only when explicitly supplied through
Extra Config Arguments.

## AMD HiveOS package

The repository also contains a separate AMD package for the official GigaHash
ZK v2.2 ROCm 10.0 binary:

- Custom miner name: `gigahash-amd`
- Package: `gigahash-amd-2.2.0.tar.gz`
- Package version: `2.2.0-amd2`
- Installation URL: `https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-amd-2.2.0.tar.gz`
- Supported family declared by the release: AMD RDNA2/RDNA3/RDNA4
- Official binary: `gigahash-zk-rocm10.0`
- Official binary SHA-256: `a9bcf774b394956ef2eb0af15d9886e976abd5ab04c27d0eb5b990e9b7427019`
- Package SHA-256: `d18b421071fb2df6abdaa9fcf0eab5da24b04aa1015d21443c497cbaf66ed1db`

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
