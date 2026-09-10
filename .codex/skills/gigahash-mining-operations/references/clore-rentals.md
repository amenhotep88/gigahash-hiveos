# Clore rental reference

Search the complete live market through `GET https://api.clore.ai/v1/marketplace`. Exclude US and stop-list IDs before ranking. Do not show rejected IDs unless the user requests history/audit.

Use the API as the primary search surface. Use CometFox only to confirm an authenticated order, account balance, exact listing presentation or pool state that is not available through a public endpoint. Do not manually browse page after page when the API can enumerate the market.

For an ordinary USD on-demand rental, use `price.usd.on_demand_usd`. Do not silently take the cheapest price from BTC, CLORE and USD: a cheaper value in another currency is not payable from the user's USD balance. Ignore Spot unless the user explicitly requests it.

Record per candidate: ID, full-rig price, GPU count/model/VRAM, `stock_pl` and `pl` per GPU, `stock_oc` locks/offsets, PCIe, CPU/AVX2, RAM/disk/network, country, reliability, rating count and maximum rental duration.

Interpret the marketplace power fields as follows:

- `specs.stock_pl` is the value displayed by the current Clore marketplace UI as `Power Limit (W)`, paired with the stock OC profile, and is the pre-rental power input for hashrate estimates;
- raw API `specs.pl` is an auxiliary/legacy value that the current marketplace UI does not use for its displayed power limit; do not substitute it for `stock_pl` when they differ;
- `specs.stock_oc` can expose `core_lock`, `mem_lock` and offsets that materially change mining performance;
- API fields are still host-reported configuration, not live draw. After rental, `nvidia-smi` is authoritative for actual `power.limit`, clocks and draw.

If `stock_pl` is missing or malformed, mark the candidate high-risk instead of falling back silently to `pl`. A profile with suspiciously low locks must be rejected or explicitly discounted; the measured `1470/810 MHz` RTX 3070 profile on server `92225` produced only about `1.13 kp/s` per GPU despite a `270 W` displayed power limit.

Use conservative hashrate based on measured configurations. Compute gross, rent, net, margin, break-even price and a stress case. A new concrete ID needs risk discount; replace estimates with observed hashrate immediately after startup.

Do not treat “v2.3 gives 10–15% more” as a universal multiplier. The uplift is measured on the user's RTX 3070 and RTX 3080 systems. Use a conservative 10% uplift only for a sufficiently similar, unrestricted Ampere profile; use exact v2.3 observations where available; otherwise apply no uplift or mark the estimate low-confidence. Never use the uplift to rescue an otherwise unprofitable listing.

Rank by conservative net USD/day first, then conservative margin, reliability/rating evidence and maximum duration. The user's current target is a multi-GPU rig producing at least `$5/day` conservative net with about `40%+` margin and at least 24 hours available. If none exists, say so and show at most the closest safe near-misses; never lower the threshold silently. Do not recommend candidates below `$1.5/day` conservative net unless the user explicitly changes the floor.

After rental, verify actual GPU inventory, current PL and clocks before downloading. `Insufficient Permissions` when changing PL is expected on Clore and means the host profile cannot be corrected by the renter.

Do not reject PCIe x1 or a weak CPU by itself. NOCK ZK has worked on x1 and Celeron hosts. Evaluate the combined evidence: `stock_pl`, locks, RAM, driver, stability and measured hashrate.

Current stop-list: `102592`, `113763`, `78799`, `90887`, `113052`, `114382`, `78139`, `114377`, `106744`, `107945`, `77956`, `105060`, `93639`, `92225`, `114418`, `110681`, `87746`, `109004`.

Use worker `clore-SERVER_ID`; Clore containers use Supervisor rather than systemd.
