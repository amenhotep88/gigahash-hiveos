# Server operations reference

## Clore

Run one Supervisor-managed `gigahash-zk-12.9` process per container. Confirm `RUNNING`, one process only, actual GPU/PL/clocks/VRAM, stable hashrate and Accepted/Stale/Errors.

## Local Ubuntu

Use systemd with `Restart=always`, explicit worker name, `ExecStartPre` core lock only when proven for the exact GPU, and `ExecStopPost=-/usr/bin/nvidia-smi -i 0 -rgc`.

Before replacing NoSSD, discover every starter:

- `miner.service`;
- root cron `/usr/local/bin/monitor.sh`;
- `nossd-disks.timer` and `nossd-disk-manager.sh`;
- other timers, which must be classified rather than disabled blindly.

Save root cron to `/root/root.crontab.before-gigahash`, comment only monitor.sh, disable miner and disk timer, and leave `nossd-vpn-subscription-update.timer` active. Verify GPU is free before GigaHash.

Rollback order: stop/disable GigaHash, reset GPU clock lock, restore saved root cron, enable disk timer, enable miner, then verify NoSSD process and disk arguments.

Known local settings:

| Worker | GPU | Lock | PL | Instances | kp/s |
|---|---|---:|---:|---:|---:|
| `rz2-3080` | RTX 3080 | 1500 | 210 | 2 | ~7.2 |
| `rzserv-3080` | RTX 3080 | 1500 | 260 | 2 | ~7.4 |
| `x99-3070` | RTX 3070 8 GB | 1400 | 170 | 1 | ~4.6 |
