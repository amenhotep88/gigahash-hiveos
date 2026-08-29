# GigaHash release checklist

## Prepare

- [ ] Official URL is from GigaHash.
- [ ] Binary size, SHA-256, `--version`, and relevant `--help` output are captured.
- [ ] Wrapper, manifest, stats, build, tests, README, handoff, and workflow use one consistent version set.
- [ ] Deterministic mirror archive builds twice to the same SHA.
- [ ] Mirror part count and reconstruction are verified.
- [ ] Current tree contains no split/PRL/SRB release references.

## Validate

- [ ] Every `tests/*.sh` passes.
- [ ] `./build.sh` succeeds.
- [ ] Package SHA and contents match documentation.
- [ ] `git diff --check` passes.
- [ ] Full staged diff contains only intended files.
- [ ] Commit is created only after fresh evidence.

## Publish

- [ ] User explicitly authorized this push/release operation.
- [ ] Branch and commits-to-push were stated.
- [ ] Push is non-force.
- [ ] Action downloaded and verified the official binary.
- [ ] Action built one standard package.
- [ ] Tag targets the intended published asset commit.

## Verify remote

- [ ] Remote `main` SHA is correct.
- [ ] Workflow concluded successfully.
- [ ] Release has exactly the expected standard asset.
- [ ] Downloaded asset SHA matches local/package notes.
- [ ] jsDelivr installation URL downloads a valid archive.
- [ ] Handoff records the final commit, tag, package and verification result.

If any item fails, stop at that boundary and report the exact evidence. Do not compensate with a force push, repeated release creation, or broad deletion.
