# Live price, pool and network inputs

Read this file before any live profitability, network-dynamics or worker-health calculation.

## SafeTrade executable NOCK price

Primary public REST endpoints documented by SafeTrade:

- all tickers: `https://safe.trade/api/v2/peatio/public/markets/tickers`;
- NOCK/USDT order book: `https://safe.trade/api/v2/peatio/public/markets/nockusdt/order-book`;
- recent trades: `https://safe.trade/api/v2/peatio/public/markets/nockusdt/trades`.

Do not value mined NOCK from a page title, cached search result or 24-hour average. Use:

1. Best bid for a small immediate sale.
2. For a material daily/payout quantity, walk the bid side of the order book and calculate volume-weighted executable sale price for that NOCK amount.
3. Subtract the actual trading fee and show slippage separately.
4. Record response time and reject empty, stale, malformed or non-`nockusdt` data.
5. Cross-check against another current market source. A divergence above 5% requires a warning and a liquidity/network investigation before screening.

SafeTrade may return a Cloudflare `403/522` to a datacenter HTTP client. This is not a zero price and not permission to reuse an old price. Retry once through the user's CometFox browser and read the live NOCK/USDT bid book.

Another exchange such as Kraken may be treated as executable only after confirming all of: a live trading pair and bid-book depth, user/account availability, deposits open, compatibility between the GigaHash payout asset/network and the exchange deposit network (or a tested bridge), and bridge/deposit/trading costs. A ticker best bid alone is only `reference`. If no venue passes those checks, use the user's `$0.025` stress price only for a clearly provisional screen and do not make a precise rent recommendation.

Default stress price requested by the user is `$0.025/NOCK`; also show break-even price. Do not replace the live base price with the stress price.

## GigaHash public pool API

Use these first-party endpoints:

- pool rules: `GET https://gigahash.cloud/api/v1/info`;
- current targets and pool totals: `GET https://gigahash.cloud/api/v1/pool`;
- per-gateway accepted work: `GET https://gigahash.cloud/api/v1/gateways`;
- account: `GET https://gigahash.cloud/api/v1/miners/{PAYOUT_ADDRESS}`;
- account hashrate history: `GET https://gigahash.cloud/api/v1/miners/{PAYOUT_ADDRESS}/hashrate-history`;
- recent account shares: `GET https://gigahash.cloud/api/v1/miners/{PAYOUT_ADDRESS}/shares?limit=N`;
- account payouts: `GET https://gigahash.cloud/api/v1/miners/{PAYOUT_ADDRESS}/payouts?limit=N`;
- pool hashrate history: `GET https://gigahash.cloud/api/v1/hashrate-history`.

These routes are known exact endpoints. Do not probe guessed `/api`, `/stats`, `/info` or version variants. A browser is not the first fallback merely because one generic HTTP request timed out.

### Required transport retry sequence

Fetch each endpoint with IPv4, HTTP/1.1, compression support, bounded timeouts and a non-empty JSON check. Start with `/api/v1/info`:

```bash
BODY="$(curl -4 --http1.1 --compressed -fsS \
  --connect-timeout 10 --max-time 25 \
  --retry 2 --retry-all-errors \
  -H 'Accept: application/json' \
  'https://gigahash.cloud/api/v1/info')"

test -n "$BODY"
printf '%s' "$BODY" | python3 -c \
  'import json,sys; x=json.load(sys.stdin); assert isinstance(x.get("pool_fee_basis_points"), (int,float))'
```

Then request `/api/v1/pool`, `/api/v1/gateways` and the exact miner routes with the same transport options and schema validation. Treat `HTTP 200` with an empty body as a failed/proxied response, never as valid pool data.

If one complete retry sequence still fails, use the user's authenticated **CometFox** browser to read the live official pool UI. Label those values `browser-observed`. Do not waste time trying invented endpoint variants. If neither the API nor the official UI exposes a required current input, mark that input unavailable instead of fabricating it.

Validate `generated_at`, target `observed_at`, node height and response schema. Do not combine values from substantially different timestamps without saying so.

## Do not confuse these metrics

### Network ZK hashrate

From `/api/v1/pool`:

```text
p = network_targets.zk.expected_blocks_per_unit_work
network_ZK_proofs_per_second = 1 / p / 214
```

`214` seconds is the current ideal ZK block interval used by the official pool frontend. A larger `p` means easier ZK target, lower implied network hashrate and greater expected output per proof. A smaller `p` means higher difficulty/network hashrate and lower output.

### GigaHash pool ZK hashrate

From `/api/v1/gateways`, sum only gateways where `online=true` and `node_healthy=true`:

```text
pool_ZK_proofs_per_second = sum(zk.accepted_work_per_second)
```

If that field is absent, use the official fallback per gateway:

```text
zk.accepted_shares_per_minute * zk.share_difficulty / 60
```

Pool hashrate is the pool's accepted work, not the entire Nockchain network. Worker count is neither network difficulty nor network hashrate.

### Expected NOCK per kp/s/day

Mirror the official `gigahash.cloud/app.js` calculation rather than inventing a fixed coefficient:

```text
BLOCK_REWARD_NOCK = 1638.4
SECONDS_PER_DAY = 86400
pool_fee = pool_fee_basis_points / 10000
proof_survival = official cross-puzzle orphan-risk factor

NOCK_per_kps_day =
    1000 * p * SECONDS_PER_DAY * proof_survival
    * BLOCK_REWARD_NOCK * (1 - pool_fee)
```

The official frontend currently computes ZK `proof_survival` from both ZK and AI chainwork and a two-second ZK build-plus-propagation window. Prefer copying the current calculation from `https://gigahash.cloud/app.js`, because consensus constants can change. Cross-check the result against the pool account's displayed estimated NOCK/day or USD/day for a known worker.

### Network dynamics

To claim growth or decline, compare timestamp-aligned `p` or implied network hashrate snapshots over the requested interval. Report:

```text
network_change_percent = (network_hash_now / network_hash_then - 1) * 100
yield_change_percent = (NOCK_per_kps_now / NOCK_per_kps_then - 1) * 100
```

`/api/v1/hashrate-history` is pool history, not automatically network history. If no earlier network-target snapshot exists, state that the current level is known but the 24/48-hour network trend is not proven. Do not infer it from rental profitability, pool hashrate, active workers or coin price.

## Source provenance

- SafeTrade API documentation: `https://safetrade.com/api`
- GigaHash public site and frontend formula: `https://gigahash.cloud/` and `https://gigahash.cloud/app.js`
