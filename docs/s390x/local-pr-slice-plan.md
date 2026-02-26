# Local PR Slice Plan (No Push / No PR Yet)

This plan keeps all work local while making the current branch easy to split into upstream-ready PRs later.

## Scope Rules

- Keep architecture-impacting changes isolated and reviewable.
- Keep test/harness and docs slices separate from datapath behavior changes.
- Do not include raw log archives in upstream PRs.

## Slice Order

1. `bpf-datapath`
2. `bpf-tests`
3. `go-tests`
4. `harness`
5. `build-tooling`
6. `docs-local` (local evidence and reporting only)

## Staging Helper

Use:

```bash
test/s390x/local_pr_slice_stage.sh <slice>
```

Then commit locally:

```bash
git commit -m "<slice message>"
```

## Suggested Local Commit Messages

1. `bpf: make datapath helpers endian-stable on s390x`
2. `bpf/tests: fix portability and verifier-sensitive cases for s390x`
3. `tests(go): normalize endian-sensitive fixtures and add bpf byteorder coverage`
4. `test/s390x: harden harness execution and image/tag fallback behavior`
5. `build: harden local image/git metadata paths for unborn-head workflows`
6. `docs(s390x): update run ledger, journals, and upstream draft notes`

## Validation Gates Per Slice

1. `bpf-datapath`
   - `make -C bpf tests`
   - `go test ./pkg/bpf -run "TestNormalizeCollectionSpecByteOrder|TestNativeByteOrder"`
2. `bpf-tests`
   - `test/s390x/bpf_regression_subset.sh`
3. `go-tests`
   - `go test ./pkg/act ./pkg/bpf ./pkg/datapath/iptables ./pkg/datapath/sockets ./pkg/hubble/parser/debug ./pkg/hubble/parser/threefour ./pkg/hubble/testutils`
4. `harness`
   - strict path: `REQUIRE_COREDNS=true HOST_TO_POD_TARGET=coredns RUN_POLICY_INTEGRATION=true RUN_BPF_REGRESSION_SUBSET=true test/s390x/launch_logged_run.sh`
   - non-strict path: `REQUIRE_COREDNS=false HOST_TO_POD_TARGET=cilium-health RUN_POLICY_INTEGRATION=true RUN_BPF_REGRESSION_SUBSET=true test/s390x/launch_logged_run.sh`
5. `build-tooling`
   - `make -n stop-kvstores SKIP_KVSTORES=true`
   - `make -n -C images image`
6. `docs-local`
   - `rg -n "/Users/|/home/" docs/s390x docs/s390x-upstream-issue-pr-drafts.md`

## Notes

- `docs-local` is local tracking/reporting support and should be omitted from upstream PRs unless specifically requested.
- The strict CoreDNS harness path is now validated on `kdz` (`r102`), with fallback to cached CRI image tags when the default local tag is missing.
