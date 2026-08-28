# GigaHash + PRL split for redrig

HiveOS custom miner package that launches two GPU miners from one Custom Miner:

- GPU `0,1,2,3`: GigaHash NOCK ZK v1.9, `--instances 2`, `--low-cpu`;
- GPU `4,5,6,7`: SRBMiner-MULTI v3.6.0, `pearlhash`, Kryptex PRL pool.

The official binaries are downloaded at runtime and verified with SHA-256. If
HiveOS already has `/hive/miners/custom/srbminer_custom`, that SRBMiner binary
is reused to avoid another GitHub release download.

## Flight Sheet

- Coin: NOCK
- Wallet: the existing NOCK wallet
- Pool: Configure in miner
- Miner: Custom
- Miner name: `gigahash-prl-split`
- Wallet and worker template: `%WAL%`
- Pool URL: `ru1.gigahash.cloud:9100`
- Pass: blank
- Extra config arguments: blank

The PRL wallet and Kryptex pool are pinned in this personal split package.
GigaHash v1.9 low-CPU mode is pinned for the NOCK half because this split runs
on a CPU-constrained eight-GPU rig. It reduces host CPU load, uses more VRAM,
and can reduce NOCK hashrate. It does not affect the PRL process.
HiveOS reports NOCK as the primary algorithm on GPUs `0,1,2,3` and PearlHash
as the secondary algorithm on GPUs `4,5,6,7`. The secondary stats use the
SRBMiner API and PCI bus mapping, so the dashboard keeps the incompatible hash
units separate. PRL output also remains available in the miner console,
SRBMiner API port `21550`, and the Kryptex dashboard.
