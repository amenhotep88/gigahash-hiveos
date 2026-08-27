# GigaHash ZK v1.8 — HiveOS Custom Miner 1.8.1

Unofficial HiveOS wrapper for the official `gigahash.cloud` NOCK ZK CUDA miner.
The proprietary miner binary is **not bundled**. On first start, the wrapper reconstructs the official HiveOS archive from a jsDelivr mirror and verifies both the archive and binary SHA-256 checksums.

## Flight Sheet

- Miner: **Custom**
- Installation URL: `https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-1.8.1.tar.gz`
- Hash algorithm: leave blank / `----`
- Wallet and worker template: **`%WAL%`**
- Pool URL: `ru1.gigahash.cloud:9100`
- Pass: blank
- Extra Config Arguments: optional native GigaHash CLI args, e.g. `--devices 0,1,2,3,4,5`

The HiveOS rig name is passed automatically as `--worker-name`. Use `%WAL%` only;
the wrapper also strips a matching `.worker-name` suffix defensively when HiveOS adds one.

## NOCK + PRL split package

The repository also publishes a dedicated `redrig` package that works around
HiveOS's one-Custom-Miner-per-Flight-Sheet limitation by launching both miners
from one wrapper:

- GPU `0,1,2,3`: GigaHash NOCK ZK v1.8 with `--instances 2`;
- GPU `4,5,6,7`: SRBMiner-MULTI v3.6.0 `pearlhash` on Kryptex.

Installation URL:

`https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-prl-split-1.0.3.tar.gz`

Use the existing NOCK wallet, `%WAL%` template, and pool URL
`ru1.gigahash.cloud:9100`. Leave Extra Config Arguments blank. Full details are in
[`split/gigahash-prl-split/README.md`](split/gigahash-prl-split/README.md).

## Stats

HiveOS displays GigaHash proof rate using its generic hash-rate fields:
- `1 proof/s` is represented as `1 H/s`
- `23.5 kp/s` is therefore shown as approximately `23.5 kH/s`

Per-GPU proof rate, temperature and fan are read from the native JSON stats file added by GigaHash, with console-table parsing retained as a fallback.
The local GigaHash `Accepted` counter is deliberately not exported because it can stay at zero even while the pool account page reports valid accepted shares.
Miner output is mirrored to both the `miner` console and the log used by HiveOS stats.

## Official miner pinned by this package

- GigaHash ZK: v1.8
- CUDA build: 12.9
- URL: `https://cdn.gigahash.cloud/releases/1.8/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9`
- SHA256: `bd0c9ca5b626fceb1e7c71cb852073a1b4c30cdc6477925947e589d27b19139c`

## Miner changes observed in v1.8

- native atomic JSON statistics through `--stats-file PATH`;
- separate `--proxy HOST[:PORT]` option with default port `9200`;
- `--server HOST[:PORT]` now defaults to public-pool port `9100`;
- updated official ZK binary and checksum.

The v1.8 binary, official HiveOS package, command-line interface, and checksum
were verified directly from the GigaHash CDN before this wrapper was built.

## Notes

The default endpoint is the developer-provided Russian server
`ru1.gigahash.cloud:9100`, manually verified from `redrig` at about 22 ms.
