# s390x Validation Docs

This directory is the local source of truth for s390x validation history,
evidence logs, and upstream-ready issue/PR notes.

## Contents

- `docs/s390x/reporting-flow.md`: canonical run logging and reporting process.
- `docs/s390x/local-pr-slice-plan.md`: local-only commit slicing plan for upstream-ready PR chunks.
- `docs/s390x/zkd0-build-journal-YYYY-MM-DD.md`: daily operational journal.
- `docs/s390x/logs/`: raw run logs grouped by UTC date.
- `docs/s390x-upstream-issue-pr-drafts.md`: upstream issue/PR draft material.

## Companion Forks and Build Order

Validated bring-up uses these local forks in dependency order:

1. `image-tools-s390x`
2. `envoy-s390x`
3. `proxy-s390x`
4. `hubble-ui-s390x`
5. `certgen-s390x`
6. `ztunnel-s390x` (ambient dataplane follow-up scope)
7. `cilium-s390x`

Recommended order of operations for reproducible `s390x` bring-up:

```bash
# 1) build dependency images
cd ../image-tools-s390x
INCLUDE_S390X=true PLATFORMS=linux/s390x make tester-image compilers-image llvm-image bpftool-image

# 2) build cilium-envoy
cd ../proxy-s390x
ARCH=s390x make docker-image-envoy

# 3) build optional components used in full Cilium install footprint
cd ../hubble-ui-s390x
ARCH=s390x make hubble-ui hubble-ui-backend

cd ../certgen-s390x
make docker-image

# 4) deploy and validate Cilium on cluster
cd ../cilium-s390x
test/s390x/deploy_cilium_s390x.sh
test/s390x/smoke_status.sh
test/s390x/multinode_matrix.sh
test/s390x/multinode_policy_enforcement.sh
test/s390x/nodeport_crossnode.sh
```

## Working Rules

- Keep logs append-only. Do not rewrite historical `.log` evidence files.
- Use repo-relative paths in docs (avoid machine-specific absolute paths).
- Keep timestamps in UTC (`YYYYMMDDTHHMMSSZ`).
- Keep architecture-sensitive notes explicit (`s390x`, `BE`) and scoped.
- Do not introduce behavior changes for non-s390x paths during remediation.
