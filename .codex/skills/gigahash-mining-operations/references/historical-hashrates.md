# Measured GigaHash NOCK ZK history

Use these as configuration-specific observations, not universal GPU specifications. Prefer the newest stable same-version, same-PL observation. Discount estimates when locks, memory clocks, driver, cooling, topology or host stability differ.

## Useful working baselines

| GPU/configuration | Miner | Observed rate | Interpretation |
|---|---:|---:|---|
| RTX 3070, core ~1400 MHz, PL 170 W | v2.0 | ~4.68 kp/s | Owned `x99` baseline before upgrade. |
| RTX 3070, core ~1410 MHz, PL 170 W | v2.3 | ~5.15–5.18 kp/s | Owned `x99`; about 10–11% over v2.0. |
| RTX 3080, core 1500 MHz, PL 210 W | v2.0 | ~7.17–7.20 kp/s | Owned `rz2` baseline. |
| RTX 3080, core 1500 MHz, PL 210 W | v2.3 | ~8.15–8.17 kp/s | Owned `rz2`; about 13% over v2.0. |
| RTX 3080, core 1500 MHz, PL 260 W | v2.0 | ~7.20–7.24 kp/s | Owned `rzserv` baseline. |
| RTX 3080, core 1500 MHz, PL 260 W | v2.3 | ~8.14–8.16 kp/s | Owned `rzserv`; about 13% over v2.0. |
| 4× RTX 3080, PL 220 W/card | v2.0 | ~29.7–29.9 kp/s total | About 7.4–7.5 kp/s/card; stable on Celeron. |
| 7× RTX 3080, PL 220 W/card | v2.0 | ~52.3 kp/s total | About 7.47 kp/s/card; stable on Celeron. |
| RTX 5060 Ti, PL 180 W | v2.0 | ~7.6 kp/s | One measured working card. |
| 2× RTX 5070, PL 250 W/card | v2.0 | ~21.3 kp/s total | About 10.6–10.7 kp/s/card on a healthy rig. |
| 4× RTX 5070, PL 250 W/card | v2.2 | ~43.8 kp/s total | About 10.9–11.0 kp/s/card. |
| 3× RTX 5070 Ti, PL 300 W/card | v2.0 | ~45.1 kp/s total | About 15.0 kp/s/card; hot card reached ~83 C. |
| RTX 5070 Ti, PL 250 W | v2.3 | ~12.5 kp/s | Server `109004`; working but insufficiently profitable. |
| RTX 5090, PL ~600 W | older build | ~32.9 kp/s | High-PL working observation; do not extrapolate to restricted 5090s. |

## Failed, restricted or misleading observations

| Server/configuration | Result | Rule |
|---|---|---|
| `92225`, 8× RTX 3070, core_lock 1470, mem_lock 810 | ~9 kp/s total, ~1.13 kp/s/card | Reject this lock pattern; nominal PL 270 W was misleading. |
| `93639`, 4× RTX 3090 | GPU workers repeatedly stopped at 4 and 2 instances/card; single-GPU test also exited | Reject server; do not infer a stable 3090 baseline from startup spikes. |
| `114418`, mixed 4070 Ti/5070 | All GPU workers stopped | Avoid mixed/uncertain rigs unless separately proven. |
| `110681`, 2× RTX 5070 | ~16.8 kp/s total; one card frequency-restricted | Reject server; do not use it as the healthy 5070 baseline. |
| `87746`, 5× CMP 90HX | `No CUDA device detected` | Do not offer CMP 90HX for this miner. |
| `109004`, RTX 5070 Ti, actual PL 250 W | ~12.5 kp/s on v2.3 | Working but canceled for economics; listing assumptions had been too high. |
| `114377`, RTX 4090, PL 450 W | ~10.1 kp/s | Concrete host underperformed model expectations. |
| `106744`, 2× RTX 5060 Ti | Actual PL 180+150 W; renter could not change it | Reject when advertised and actual PL differ materially. |
| `107945`, 2× RTX 4070 | Actual PL 130 W/card; renter could not change it | Reject restricted cards. |
| `77956`, 2× RTX 3080 Ti, PL 300 W | ~18.8 kp/s total | Use ~9.4 kp/s/card for that host, not a mixed-rig anomaly. |
| RTX 5090, PL 450 W | ~11.2–11.4 kp/s | Severe restriction versus 600 W observation; PL materially changes this workload. |

## Estimation rules

1. Use exact measured v2.3 data for the same card and comparable PL when available.
2. For RTX 3070/3080 with comparable unrestricted clocks, v2.0→v2.3 uplift may be estimated at 10%, not 15%.
3. For other families, do not add a universal v2.3 uplift. Mark the estimate low-confidence or use a measured v2.3 result.
4. Apply `stock_pl` and stock lock constraints before calculating revenue. A high raw `pl` cannot override a low `stock_pl` or bad `stock_oc`.
5. Apply a further 15% risk discount to a new untested server unless strong same-host evidence exists.
6. After rental and warm-up, replace every estimate with measured total/per-GPU hashrate and recalculate keep/cancel economics.
