# GigaHash ZK v1.7 — HiveOS Custom Miner 1.7.0

Unofficial HiveOS wrapper for the official `gigahash.cloud` NOCK ZK CUDA miner.
The proprietary miner binary is **not bundled**. On first start, the wrapper downloads it directly from the official GigaHash CDN and verifies its SHA-256 checksum.

## Flight Sheet

- Miner: **Custom**
- Installation URL: `https://raw.githubusercontent.com/amenhotep88/gigahash-hiveos/main/gigahash-1.7.tar.gz`
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

Per-GPU proof rate, temperature and fan are read from the native JSON stats file added by GigaHash, with console-table parsing retained as a fallback.
The local GigaHash `Accepted` counter is deliberately not exported because it can stay at zero even while the pool account page reports valid accepted shares.
Miner output is mirrored to both the `miner` console and the log used by HiveOS stats.

## Official miner pinned by this package

- GigaHash ZK: v1.7
- CUDA build: 12.9
- URL: `https://cdn.gigahash.cloud/releases/1.7/ubuntu20.04-cuda12.9.2/gigahash-zk-12.9`
- SHA256: `b1f8c91172dc5f84fc7648ae9119b525efbc4d6953e267549bad4a4d17617ea1`

## Miner changes observed in v1.7

- native atomic JSON statistics through `--stats-file PATH`;
- separate `--proxy HOST[:PORT]` option with default port `9200`;
- `--server HOST[:PORT]` now defaults to public-pool port `9100`;
- updated official ZK binary and checksum.

No separate upstream v1.7 changelog was published at the time this package was built. The list above is based on the official v1.6/v1.7 command-line interfaces and release files.

## Notes

The default GigaHash hostname may resolve to multiple pool IPs. If your ISP reaches only some of them reliably, put a working `HOST:PORT` directly into HiveOS Pool URL.

The v1.7 CDN briefly served a stale binary for the plain release URL. The wrapper uses a versioned query string to bypass that stale edge-cache entry and still verifies the official SHA-256 before execution.
