# GigaHash ZK v2.0 — HiveOS Custom Miner 2.0.0

Unofficial HiveOS wrapper for the official `gigahash.cloud` NOCK ZK CUDA miner.
The proprietary miner binary is **not bundled**. On first start, the wrapper reconstructs a mirror archive built from the official v2.0 binary and verifies both the archive and binary SHA-256 checksums.

## Flight Sheet

- Miner: **Custom**
- Installation URL: `https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-2.0.0.tar.gz`
- Hash algorithm: leave blank / `----`
- Wallet and worker template: **`%WAL%`**
- Pool URL: `ru1.gigahash.cloud:9100`
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

- GigaHash ZK: v2.0
- CUDA build: 12.9
- URL: `https://cdn.gigahash.cloud/releases/2.0/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9`
- SHA256: `ec6b9a9fed28b34c3d2b33bae381021d7ae4704f0bd295841cea6bd555f7a0a7`

## Miner changes observed in v2.0

- lower host RAM usage;
- less PCIe traffic;
- added `--backup-server` for an explicit fallback endpoint;
- retained optional `--low-cpu`, `--devices`, and native JSON stats support.

The v2.0 binary, command-line interface, and published checksum were verified
directly from the GigaHash CDN before this wrapper was built. Low-CPU mode and
backup endpoint overrides are enabled only when explicitly supplied through
Extra Config Arguments.

## Notes

The default endpoint is the developer-provided Russian server
`ru1.gigahash.cloud:9100`, manually verified from `redrig` at about 22 ms.
