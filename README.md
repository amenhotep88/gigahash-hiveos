# GigaHash ZK v1.6 — HiveOS Custom Miner 1.6.1

Unofficial HiveOS wrapper for the official `gigahash.cloud` NOCK ZK CUDA miner.
The proprietary miner binary is **not bundled**. On first start, the wrapper downloads it directly from the official GigaHash CDN and verifies its SHA-256 checksum.

## Flight Sheet

- Miner: **Custom**
- Installation URL: URL of `gigahash-1.6.tar.gz`
- Hash algorithm: leave blank / `----`
- Wallet and worker template: **`%WAL%`**
- Pool URL: e.g. `84.32.220.164:9100` or `server.gigahash.cloud:9100`
- Pass: blank
- Extra Config Arguments: optional native GigaHash CLI args, e.g. `--devices 0,1,2,3,4,5`

The HiveOS rig name is passed automatically as `--worker-name`. Use `%WAL%` only;
the wrapper also strips a matching `.worker-name` suffix defensively when HiveOS adds one.

## Stats

HiveOS displays GigaHash proof rate using its generic hash-rate fields:
- `1 proof/s` is represented as `1 H/s`
- `23.5 kp/s` is therefore shown as approximately `23.5 kH/s`

Per-GPU proof rate, temperature and fan are parsed from the GigaHash console table.
The local GigaHash `Accepted` counter is deliberately not exported because it can stay at zero even while the pool account page reports valid accepted shares.
Miner output is mirrored to both the `miner` console and the log used by HiveOS stats.

## Official miner pinned by this package

- GigaHash ZK: v1.6
- CUDA build: 12.9
- URL: `https://cdn.gigahash.cloud/releases/1.6/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9`
- SHA256: `1a417bb361079d134768b4427964dd46aa9ba5f03ce997dfdf684487bb514f96`

## Notes

The default GigaHash hostname may resolve to multiple pool IPs. If your ISP reaches only some of them reliably, put a working `HOST:PORT` directly into HiveOS Pool URL.
