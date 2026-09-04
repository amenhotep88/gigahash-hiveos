# Clore rental reference

Search the complete live market. Exclude US and stop-list IDs before ranking. Do not show rejected IDs unless the user requests history/audit.

Record per candidate: ID, full-rig price, GPU count/model/VRAM, PL and lock per GPU, PCIe, CPU/AVX2, RAM/disk/network, country, reliability, rating count and maximum rental duration.

Use conservative hashrate based on measured configurations. Compute gross, rent, net, margin, break-even price and a stress case. A new concrete ID needs risk discount; replace estimates with observed hashrate immediately after startup.

After rental, verify actual GPU inventory and current PL before downloading. `Insufficient Permissions` when changing PL is expected on Clore and means advertised PL cannot be corrected by the renter.

Current stop-list: `102592`, `113763`, `78799`, `90887`, `113052`, `114382`, `78139`, `114377`, `106744`, `107945`, `77956`, `105060`.

Use worker `clore-SERVER_ID`; Clore containers use Supervisor rather than systemd.
