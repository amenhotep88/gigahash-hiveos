# GigaHash + PRL split for redrig

HiveOS custom miner package that launches two GPU miners from one Custom Miner:

- GPU `0,1,2,3`: GigaHash NOCK ZK v1.8, `--instances 2`;
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
HiveOS reports the NOCK rate because NOCK and PearlHash use incompatible hash
units. PRL output remains visible in the miner console, SRBMiner API port
`21550`, and the Kryptex dashboard.
