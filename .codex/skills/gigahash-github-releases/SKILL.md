---
name: gigahash-github-releases
description: Use when preparing, validating, publishing, inspecting, or cleaning Git commits, tags, GitHub Actions, Releases, release assets, jsDelivr mirror parts, or version updates for amenhotep88/gigahash-hiveos.
---

# GigaHash GitHub Releases

## Overview

Release one verified standard HiveOS wrapper per official GigaHash ZK version. Keep source identity, hashes, package contents, Git state, workflow output, and GitHub assets auditable.

## Start every GitHub task

1. Read `docs/HANDOFF_CURRENT_2026-08-29.md` and `docs/GITHUB_RELEASE_RUNBOOK.md`.
2. Run `git status --short --branch`, inspect remotes and recent commits.
3. Inventory exact tags/releases/assets before any deletion or replacement.
4. Obtain explicit user authorization immediately before `push`, Release mutation, asset deletion, tag deletion, or history rewrite.

Authorization for one commit or asset does not authorize later mutations. Never force-push during an ordinary version update.

## Current release contract

- Repository: `amenhotep88/gigahash-hiveos`.
- Active product: standard GigaHash ZK HiveOS package only.
- Current binary/package: v1.9 / `gigahash-1.9.0.tar.gz`.
- Split, PRL, PearlHash, and SRBMiner assets are discontinued and must not be published.
- Official binary origin and SHA-256 must be recorded before mirror construction.

## Choose the workflow

| Request | Required route |
|---|---|
| Inspect state | Read-only Git/GitHub API; report branch, divergence, tags, workflow and assets |
| Publish version | Follow [references/release-checklist.md](references/release-checklist.md) |
| Delete bad asset | Resolve exact release and asset ID/name, delete only that asset, then re-list |
| Remove component | New deletion commit; preserve history unless the user explicitly authorizes rewriting it |
| Repair failed Action | Diagnose the first failing step; do not rerun or mutate blindly |

## Evidence gate

Before a commit or push, run fresh:

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
./build.sh
sha256sum gigahash-1.9.0.tar.gz
tar -tzf gigahash-1.9.0.tar.gz
git diff --check
git status --short --branch
```

After publishing, verify the remote branch SHA, workflow conclusion, tag target, release asset names/sizes, downloaded package SHA, and jsDelivr installation URL.

## Common mistakes

- Treating local `main` as remote truth without fetch/API verification.
- Publishing both standard and discontinued split packages.
- Creating a release before the asset commit exists remotely.
- Deleting a whole Release when only one bad asset must be removed.
- Trusting a top-level workflow status without reading the failing step.
- Exposing credentials in command output or logs.
