# Pool and profitability reference

Payout address: `W1ijDJZsLuKiLpKWzr5LYeVMnJKF8Khx9stXEBoXQfxwjEotbxppbN`.

For every pool analysis:

1. List every worker with status, age/freshness, GPU online/total, current kp/s and version.
2. Split `clore-*` from owned workers and reconcile against active Clore orders.
3. Flag an active order with no live worker, a pending worker without credited shares, duplicates and abrupt hashrate loss.
4. Report Accepted/Stale/Errors from miner logs, but use pool data for credit and payout.
5. Convert API units with `1 NOCK = 65,536 nicks`.
6. Compute actual NOCK/day from balance deltas over a stable window; when a payout crosses the window include pending, reserved, paid and payout cost deltas.
7. Use current executable NOCK/USDT price and pool fee 9% for USD estimates.
8. For the 2,000 NOCK threshold, show remaining NOCK, measured NOCK/hour, ETA, next payout batch constraint and uncertainty.

Never use an old USD/kp/s/day coefficient as a constant.
