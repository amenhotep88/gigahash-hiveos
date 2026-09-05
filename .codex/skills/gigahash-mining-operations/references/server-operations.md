# Server operations reference

## Clore

Run one Supervisor-managed `gigahash-zk-12.9` process per container. Confirm `RUNNING`, one process only, actual GPU/PL/clocks/VRAM, stable hashrate and Accepted/Stale/Errors.

### Multi-GPU loss watchdog

Supervisor does not restart `gigahash` when one CUDA worker stalls but the shared process remains alive. On a stable multi-GPU rental, install a second Supervisor program named `gigahash-watchdog`; cron may be absent in Clore containers.

The watchdog contract:

- record the expected GPU count at installation;
- every `sleep 600` (10 minutes), query index, utilization and used VRAM with `nvidia-smi`;
- declare GPU loss when the visible GPU count changes, or one GPU simultaneously reports utilization <=5% and used VRAM <1 GiB;
- serialize checks with `flock`, run `supervisorctl restart gigahash`, wait 5 minutes and log verification;
- allow at most two automatic restarts per rolling hour; after that log `restart_limit=2_per_hour` and require manual keep/cancel diagnosis;
- log events separately in `/var/log/gigahash-watchdog.log`.

Do not simulate GPU loss on a paid live rental. Verify installation with `supervisorctl status gigahash gigahash-watchdog`; both must be `RUNNING`. A successful installation proves scheduling, not the recovery path. Repeated GPU loss is a rental defect, not a reason to create an unlimited restart loop.

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
