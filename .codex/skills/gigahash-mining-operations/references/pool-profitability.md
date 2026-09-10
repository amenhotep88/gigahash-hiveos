# Pool and profitability reference

Payout address: `W1ijDJZsLuKiLpKWzr5LYeVMnJKF8Khx9stXEBoXQfxwjEotbxppbN`.

Use the authenticated CometFox browser when the user's pool dashboard is required. Inspect every worker attached to this payout address, not only worker names mentioned in the current message.

For every pool analysis:

1. List every worker with status, age/freshness, GPU online/total, current kp/s and version.
2. Split currently active, offline/historical and duplicate/session rows; do not equate the number of returned rows with connected workers.
3. Reconcile the account-level connected count and total hashrate against the enumerated active workers.
4. Split `clore-*` from owned workers and reconcile every `clore-SERVER_ID` against the authenticated Clore My orders status. Pool-offline alone does not prove that billing ended.
5. Flag an active order with no live worker, a pending worker without credited shares, duplicates and abrupt hashrate loss.
6. Report Accepted/Stale/Errors from miner logs, but use pool data for credit and payout.
7. Convert API units with `1 NOCK = 65,536 nicks`.
8. Compute actual NOCK/day from balance deltas over a stable window; when a payout crosses the window include pending, reserved, paid and payout cost deltas.
9. Use a current verified executable NOCK sale price and pool fee 9% for USD estimates.
10. For the 2,000 NOCK threshold, show remaining NOCK, measured NOCK/hour, ETA, next payout batch constraint and uncertainty.

Never use an old USD/kp/s/day coefficient as a constant.

For every profitability report, state the observation timestamp and show the live inputs used: NOCK/USD, pool NOCK per kp/s/day or equivalent network factor, pool fee, rental USD/day and hashrate basis. If the price or pool yield cannot be refreshed, stop the dollar conclusion instead of reusing a stale coefficient without a warning.

Read `live-data-sources.md` for the exact public pool and exchange endpoints, the network/pool distinction and the current yield formula. For rental decisions, use a verified executable bid-side VWAP rather than a ticker or the pool page's reference quote.
