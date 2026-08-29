# Official GigaHash version upgrade

Read `docs/HIVEOS_MINER_DEVELOPMENT.md` and `docs/GITHUB_RELEASE_RUNBOOK.md` before changing files.

## Required inputs

- official binary URL;
- exact `--version` output;
- official binary SHA-256;
- relevant `--help` changes;
- target HiveOS package version.

## Update set

Treat these as one atomic version set:

| Surface | Required update |
|---|---|
| `h-run.sh` | mirror base, part count, archive SHA, binary SHA |
| `h-manifest.conf` | package version |
| `h-stats.sh` | reported miner version |
| `build.sh` | package version and deterministic timestamp |
| `tests/` | new version/hash/part invariants |
| `README.md` | install URL, official source and observations |
| workflow | official URL/SHA, archive construction, tag, release notes |
| handoff/history | current state and measured rollout result |

## Validation sequence

1. Verify the downloaded official binary before packaging.
2. Build the deterministic archive twice and compare SHA-256.
3. Reconstruct it from mirror parts and compare SHA-256.
4. Extract the binary and compare its SHA-256 with the official download.
5. Run all repository tests and build the HiveOS package.
6. Inspect package contents and checksum.
7. Deploy to one control rig only after release authorization.
8. Compare startup, pool shares, hashrate, CPU, VRAM, Xid/OOM, and stability before fleet rollout.

Do not promote a new flag to a default because it appears in `--help`; require a controlled stability/performance test.
