# zkd0 s390x Build Journal

- Date: `2026-02-25` (UTC)
- Active execution host for heavy runs: `kdz` (`RHEL 9.6`, `s390x`, big-endian)
- Branch: `k8ika0s/s390x-local-pr-stack`
- Scope for this day: continue proxy/envoy remediation, remove recurring non-FIPS TLS compile blocker, and re-run targeted `docker-tests`.

## Baseline at Start of Day

- Carryover active run: `r86` started at `2026-02-25T00:41:31Z` on `kdz`.
- Prior completed run (`r85`) status:
  - log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r85-20260225T003106Z.log`
  - status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r85-20260225T003106Z.status`
  - `rc=2`, `ended_at=2026-02-25T00:36:39Z`

## `r85` Failure Snapshot

- Failing compile unit:
  - `external/envoy/source/common/tls/context_impl.cc:375`
- Exact blocker:
  - `error: use of undeclared identifier 'ssl_compliance_policy_fips_202205'`
- Interpretation:
  - Envoy TLS compliance-policy logic was compiled on s390x path that links non-FIPS aws-lc, where `ssl_compliance_policy_fips_202205` is not available.
  - This is independent of runtime test behavior; build exits before integration tests.

## Remediation Applied

- In `proxy-s390x`, refreshed routing patch and added new targeted guard patch:
  - `patches/0012-bazel-route-s390x-fips-to-aws-lc.patch`
    - keeps `linux_s390x` routed to aws-lc (`@aws_lc//:ssl` and `@aws_lc//:crypto`)
  - `patches/0013-bazel-envoy-guard-fips-compliance-policy-for-nonfips.patch`
    - wraps `SSL_CTX_set_compliance_policy(..., ssl_compliance_policy_fips_202205)` in `#if defined(BORINGSSL_FIPS)`.
    - non-FIPS builds now return explicit `InvalidArgumentError` instead of referencing unavailable symbol.
  - `WORKSPACE` updated to apply patch `0013`.

## Relaunch / Current Run (`r86`)

- Run metadata:
  - log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r86-20260225T004131Z.log`
  - status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r86-20260225T004131Z.status`
  - command class: `make docker-tests ARCH=s390x ...` (targeted TLS/websocket/tcp suite)
- Current state:
  - completed with `rc=0` at `2026-02-25T01:32:03Z`.
  - compile advanced beyond prior failure locus in `context_impl.cc` with no recurrence of undeclared symbol error.
  - targeted test set executed to completion (`4/4` pass), with one flaky target.

## `r86` Outcome Details

- Success criteria met for this remediation slice:
  - non-FIPS compile blocker (`ssl_compliance_policy_fips_202205` undeclared) is cleared.
  - full targeted docker-tests command finished successfully on `kdz`.
- Residual instability observed:
  - `//tests:cilium_tls_http_integration_test` marked `FLAKY` (failed once, passed on retry).
  - first attempt reached test timeout window (`~301s`) and logged Envoy shutdown crash signal:
    - `Test timed out at 2026-02-25 01:31:56 UTC`
    - `Caught Segmentation fault` in attempt output.
- Interpretation:
  - the compile-path remediation is effective.
  - a runtime/test flake remains and should be isolated before claiming full stability.

## Focused Flake Repro Launch (`r88`)

- Trigger:
  - `r86` marked `//tests:cilium_tls_http_integration_test` as `FLAKY`.
- Repro run launched on `kdz`:
  - log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r88-20260225T013342Z.log`
  - status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r88-20260225T013342Z.status`
  - target scope: `//tests:cilium_tls_http_integration_test` only
  - repro settings:
    - `--runs_per_test=5`
    - `--flaky_test_attempts=1` (disable retry masking)
    - `--test_timeout=600`
- Purpose:
  - quantify reproducibility of timeout/segfault behavior and collect cleaner failure evidence for upstream triage.
- Result:
  - `r88` completed `rc=0` at `2026-02-25T01:34:26Z`.
  - `//tests:cilium_tls_http_integration_test` passed under:
    - `--runs_per_test=5`
    - `--flaky_test_attempts=1`
  - Interpretation:
    - the `r86` timeout/segfault appears intermittent (not reproduced in immediate focused rerun).

## Broader No-Retry Stability Sweep (`r89`)

- Run launched on `kdz`:
  - log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r89-20260225T013608Z.log`
  - status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r89-20260225T013608Z.status`
- Scope:
  - same 4-target set used in `r86`:
    - `//tests:cilium_tls_http_integration_test`
    - `//tests:cilium_tls_tcp_integration_test`
    - `//tests:cilium_websocket_encap_integration_test`
    - `@envoy//test/integration:tcp_proxy_integration_test`
- Key setting:
  - `--flaky_test_attempts=1` to prevent retry masking and surface true instability.
- Result:
  - `r89` completed `rc=0` at `2026-02-25T01:36:31Z`.
  - 4-target suite passed with retries disabled; no `FLAKY` marker emitted in this run.

## Repeated-Run Stability Sweep (`r90`)

- Launch intent:
  - same 4-target set as `r89` with stronger repeated-run signal via `--runs_per_test=3`.
- Run metadata:
  - log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r90-20260225T013754Z.log`
  - status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r90-20260225T013754Z.status`
- Note:
  - first launch attempt raced script creation and failed before execution; run was immediately relaunched and is active under timestamp `013754Z`.
- Result:
  - `r90` completed `rc=0` at `2026-02-25T01:38:48Z`.
  - repeated-run configuration (`--runs_per_test=3`, `--flaky_test_attempts=1`) passed for all 4 targets.
  - no `FLAKY`, timeout, or segfault signatures observed in this run.

## Wider Proxy Sweep (`r91`)

- Run launched on `kdz`:
  - log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r91-20260225T014129Z.log`
  - status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r91-20260225T014129Z.status`
- Scope:
  - widened test target set from focused 4-target subset to:
    - `//tests/...`
    - `@envoy//test/integration:tcp_proxy_integration_test`
- Key setting:
  - `--flaky_test_attempts=1` (no retry masking).
- Result:
  - `r91` completed `rc=0` at `2026-02-25T03:27:55Z`.
  - wide no-retry proxy suite completed successfully with:
    - `Executed 10 out of 14 tests: 14 tests pass.`
  - no `FLAKY` marker observed in this run.

## Throughput Prep for Next Rerun

- Host capacity check on `kdz`:
  - `16` CPUs, `~61 GiB` RAM, `~183 GiB` free root disk.
- Prepared (not launched) rerun launcher:
  - `/root/work/proxy-r92-docker-tests-wide-fast.sh`
- `r92` launcher intent:
  - keep same widened target set as `r91` (`//tests/...` + `tcp_proxy_integration_test`)
  - raise Bazel resource caps to better match `kdz` capacity:
    - `--jobs=8`
    - `--local_cpu_resources=8`
    - `--local_ram_resources=32768`
    - `--local_test_jobs=4`
  - keep retry masking disabled (`--flaky_test_attempts=1`) for stability signal quality.
- Added a background follow watcher to remove manual latency between runs:
  - script: `/root/work/proxy-r91-follow.sh`
  - log: `docs/s390x/logs/2026-02-25/proxy-r91-follow.log`
  - behavior:
    - wait for `r91` status file
    - if `r91 rc=0`, stop
    - if `r91 rc!=0`, launch `r92` fast profile automatically.
- Watcher outcome:
  - detected `r91` completion at `2026-02-25T03:28:13Z`
  - observed `r91 rc=0`
  - exited without launching `r92`.

## Harness Logging Tooling (s390x Runtime)

- Added `test/s390x/launch_logged_run.sh` to wrap `test/s390x/run_harness.sh` with deterministic evidence output:
  - `.log` and `.status` files under `docs/s390x/logs/<UTC date>/`
  - metadata includes `run`, `component`, `host`, start/end times, rc, and harness script path.
- Updated `test/s390x/README.md` with launcher usage and environment knobs (`RUN_ID`, `RUN_COMPONENT`, `RUN_DAY`, `RUN_TS`, `LOG_DIR`, `LOG_FILE`, `STATUS_FILE`, `HARNESS_SCRIPT`).
- Validation:
  - syntax-check: `bash -n test/s390x/launch_logged_run.sh ...` passed.
  - selftest invocation with `HARNESS_SCRIPT=/usr/bin/true` produced expected `.log` and `.status` outputs.

## Focused Go Regression Sweep (`go-regression-r02`)

- Run metadata:
  - log: `docs/s390x/logs/2026-02-25/go-regression-r02-20260225T020243Z.log`
  - status: `docs/s390x/logs/2026-02-25/go-regression-r02-20260225T020243Z.status`
- Command:
  - `GOMAXPROCS=4 go test ./pkg/act ./pkg/bpf ./pkg/datapath/iptables ./pkg/datapath/sockets ./pkg/hubble/parser/debug ./pkg/hubble/parser/threefour ./pkg/hubble/testutils`
- Result:
  - `rc=0`; all targeted packages passed on `kdz` s390x.

## Regression Test Hardening (Go-side Endian Coverage)

- File updated: `pkg/bpf/collection_endian_test.go`
- Added focused tests:
  - `TestNormalizeCollectionSpecByteOrderMismatched`
  - `TestNormalizeCollectionSpecByteOrderNoop`
  - `TestNativeByteOrder`
- Validation:
  - local macOS compile path cannot build `pkg/bpf` (Linux-only probe symbols), so execution was validated on `kdz`.
  - command: `go test ./pkg/bpf -run "TestNormalizeCollectionSpecByteOrder|TestNativeByteOrder"`
  - result: `ok   github.com/cilium/cilium/pkg/bpf 0.024s`

## Operational Notes

- Daily logs are synced locally from `kdz` into:
  - `docs/s390x/logs/2026-02-25/`
- Run ledger for this date:
  - `docs/s390x/logs/2026-02-25/RUN-INDEX.md`

## Next Steps

- Promote this remediation slice as ready-for-upstream candidates:
  - s390x aws-lc routing patch (`0012`)
  - non-FIPS compliance-policy guard patch (`0013`)
- Start the next wider validation tier beyond `r91`:
  - full proxy docker-tests matrix variants
  - dependent cilium image/harness checks on `kdz`.
- Keep `r92` fast profile ready as the immediate fallback launcher for any new non-zero proxy sweep.
- Keep architecture scope strict:
  - s390x-specific routing and guards only, no behavior changes on existing amd64/arm64 paths.

## kdz Runtime Bootstrap and Kubeadm Bring-up (2026-02-25, late session)

- Objective:
  - move runtime validation from `zkd0` to `kdz` per updated execution plan (build/perf/runtime on newer host).

- Initial `kdz` state:
  - host: `RHEL 9.6` (`s390x`)
  - build tooling present (`go`, `clang`, `podman`, `make`) but no Kubernetes runtime stack:
    - missing `kubectl`, `helm`, `kubeadm`, `kubelet`, `cri-tools`, `containerd`, `runc`
    - no `/etc/kubernetes/admin.conf`
    - `kubelet`/`containerd` inactive.

- Runtime bootstrap run:
  - script staged: `/root/work/kdz-bootstrap-runtime.sh`
  - log: `docs/s390x/logs/2026-02-25/kdz-runtime-bootstrap-20260225T063245Z.log`
  - status: `docs/s390x/logs/2026-02-25/kdz-runtime-bootstrap-20260225T063245Z.status`
  - key actions:
    - added `kubernetes` repo (`v1.35` stream)
    - installed RPMs:
      - `kubeadm-1.35.1`
      - `kubelet-1.35.1`
      - `cri-tools-1.35.0`
      - `kubernetes-cni-1.8.0`
      - `conntrack-tools`, `socat`
    - installed cached host tools:
      - `/root/work/tools/kubectl` -> `/usr/local/bin/kubectl`
      - `/root/work/tools/linux-s390x/helm` -> `/usr/local/bin/helm`
    - installed runtime bits:
      - `containerd-1.7.27` from `/root/work/runtime-bootstrap/containerd-1.7.27-linux-s390x.tar.gz`
      - `runc v1.2.6` (`runc.s390x`)
      - CNI plugins from `/root/work/runtime-bootstrap/cni-plugins-linux-s390x-v1.6.2.tgz`
    - configured:
      - `/etc/systemd/system/containerd.service`
      - `/etc/containerd/config.toml` (`SystemdCgroup=true`)
      - `/etc/crictl.yaml`
      - kernel modules/sysctls for bridge forwarding and `ip_forward`.

- First kubeadm attempt result:
  - failed preflight with:
    - `[ERROR FileContent--proc-sys-net-ipv4-ip_forward]: ... not set to 1`
  - status recorded as non-zero in the run status file.

- Remediation and retry:
  - applied immediate runtime fix:
    - `sysctl -w net.ipv4.ip_forward=1`
  - reran `kubeadm init` with:
    - `--pod-network-cidr=10.244.0.0/16`
    - `--cri-socket=unix:///run/containerd/containerd.sock`
    - explicit `--apiserver-advertise-address=<kdz IP>`
  - outcome:
    - `kubeadm init` succeeded
    - `admin.conf` copied to `/root/.kube/config`
    - control-plane taint removed
    - node state after init: `NotReady` (expected pre-CNI).

- Runtime warning notes (non-fatal):
  - container runtime warning about CRI `RuntimeConfig` support deprecation path (future 1.36 behavior).
  - kubeadm warning about pause image mismatch:
    - runtime sandbox image `registry.k8s.io/pause:3.8`
    - recommended by kubeadm: `registry.k8s.io/pause:3.10.1`.

- Image availability blocker on `kdz`:
  - validated tags are not present in public registries:
    - `docker.io/cilium/cilium-dev:s390x-be-policyfix2-20260221T163855Z` -> manifest unknown
    - `docker.io/cilium/operator-dev:1233512912-nogit-wip` -> manifest unknown
    - `quay.io/cilium/cilium-envoy-dev:k8ika0s-s390x-proxy-remediate-s390x` -> manifest unknown
  - only local proxy artifact on `kdz` before seeding:
    - `quay.io/cilium/cilium-envoy-dev:k8ika0s-s390x-proxy-remediate-s390x-testlogs`.

- Image seeding in progress:
  - source host `zkd0` (containerd namespace `k8s.io`) exported:
    - `docker.io/cilium/cilium-dev:s390x-be-policyfix2-20260221T163855Z`
    - `docker.io/cilium/operator-dev:1233512912-nogit-wip`
    - `quay.io/cilium/cilium-envoy-dev:k8ika0s-s390x-proxy-remediate-s390x`
  - export tar on `zkd0`:
    - `/tmp/cilium-kdz-seed-20260225T0637Z.tar` (~`1.2G`)
  - cross-host copy to `kdz` initiated (via local relay path due missing direct host-to-host auth).

## kdz Harness Iterations (`r96` -> `r98`) and Remediation

- Baseline launch shape (all runs):
  - `KUBECONFIG=/etc/kubernetes/admin.conf`
  - `CILIUM_IMAGE_TAG=s390x-be-policyfix2-20260221T163855Z`
  - `OPERATOR_IMAGE_OVERRIDE=docker.io/cilium/operator-dev:1233512912-nogit-wip`
  - `ENVOY_IMAGE_TAG=k8ika0s-s390x-proxy-remediate-s390x`
  - `RUN_POLICY_INTEGRATION=true`
  - `RUN_BPF_REGRESSION_SUBSET=true`
  - `REQUIRE_COREDNS=false`
  - `HOST_TO_POD_TARGET=cilium-health`

### Run `r96` (failed)

- status: `docs/s390x/logs/2026-02-25/s390x-harness-r96-20260225T065322Z.status` (`rc=1`)
- log: `docs/s390x/logs/2026-02-25/s390x-harness-r96-20260225T065322Z.log`
- observed failure:
  - smoke phase failed at `host-to-pod-health` with inability to determine cilium-health endpoint IP.
- root cause:
  - `test/s390x/smoke_status.sh` parser expected only `Endpoint connectivity to <ip>:` output.
  - on `kdz`, endpoint IP was only discoverable via `cilium status --verbose` IPAM line format: `<ip> (health)`.
- remediation:
  - patched `test/s390x/smoke_status.sh` to add fallback extraction for `(<health>)` IP lines.
  - synced updated `test/s390x/*` to both `kdz` and `zkd0`.

### Run `r97` (failed)

- status: `docs/s390x/logs/2026-02-25/s390x-harness-r97-20260225T065530Z.status` (`rc=1`)
- log: `docs/s390x/logs/2026-02-25/s390x-harness-r97-20260225T065530Z.log`
- observed progression:
  - smoke checks passed
  - policy integration passed
  - BPF subset failed at packet-header generation step.
- root cause:
  - missing host Python modules:
    - `ModuleNotFoundError: No module named 'jinja2'`
    - `ModuleNotFoundError: No module named 'scapy'`
- remediation:
  - installed host deps on `kdz`:
    - `dnf install -y python3-jinja2 python3-scapy`
  - codified prereq guard in harness:
    - updated `test/s390x/bpf_regression_subset.sh` to fail fast with explicit dependency guidance if `python3`, `jinja2`, or `scapy` are absent.
  - documented host prereqs in `test/s390x/README.md`.
  - synced `test/s390x/*` updates to both `kdz` and `zkd0`.

### Run `r98` (passed)

- status: `docs/s390x/logs/2026-02-25/s390x-harness-r98-20260225T065823Z.status` (`rc=0`)
- log: `docs/s390x/logs/2026-02-25/s390x-harness-r98-20260225T065823Z.log`
- outcome:
  - smoke checks passed
  - policy integration passed
  - BPF subset passed:
    - `tc_lxc_policy_drop`
    - `tc_policy_reject_response_test`
    - `hairpin_sctp_flow`
  - artifacts captured under `/tmp/cilium-s390x-artifacts-20260225T065932Z`.

## Integration-Wide Validation (`r03`) on `kdz`

- run:
  - `HARNESS_SCRIPT=/root/work/cilium-s390x/test/s390x/integration_wide.sh`
  - via `test/s390x/launch_logged_run.sh`
  - `RUN_COMPONENT=s390x-integration-wide`, `RUN_ID=r03`
- artifacts:
  - status: `docs/s390x/logs/2026-02-25/s390x-integration-wide-r03-20260225T070058Z.status`
  - log: `docs/s390x/logs/2026-02-25/s390x-integration-wide-r03-20260225T070058Z.log`
- outcome:
  - `rc=0` (full sweep passed).
  - kvstore startup succeeded with podman MTU workaround path.
  - `go test ./...` integration corridor completed with coverage report generation.
- note:
  - noisy but non-fatal git messages were observed during make invocations on an unborn local branch state and were remediated (below).

## Build-Tooling Hardening: Unborn Branch Git Metadata Fallback

- issue:
  - `make` invocations in local-only/unborn branch repo states emitted repeated:
    - `fatal: your current branch ... does not have any commits yet`
- remediation (local + synced to `kdz`):
  - file updated: `Makefile.defs`
  - hardened git-derived shell vars:
    - `DOCKER_IMAGE_TAG` now guarded by `git rev-parse --verify HEAD` with fallback to `unknown`
    - `GIT_VERSION` now guarded by `git rev-parse --verify HEAD` with fallback to cached `GIT_VERSION` or `unknown`
- verification:
  - `make -n stop-kvstores SKIP_KVSTORES=true` on `kdz` no longer emits branch-fatal noise.

## Proxy Wide Sweep Tuning on `kdz`: `r92` fast profile vs `r93` middle profile

### Run `r92` (failed)

- status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r92-20260225T071115Z.status`
- log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r92-20260225T071115Z.log`
- profile:
  - `jobs=8`, `local_ram_resources=32768`, `local_cpu_resources=8`
- outcome:
  - `rc=2`
  - Bazel server crash during `envoy-test-deps`:
    - `Server terminated abruptly (error code: 14, error message: 'Socket closed')`
- secondary script issue:
  - patch checksum logging had malformed `cut` delimiter escaping (`cut: '"' No such file or directory`).

### Remediation and `r93` (passed)

- created tuned launcher:
  - `/root/work/proxy-r93-docker-tests-wide-mid.sh`
  - fixed checksum logging quoting
  - reduced profile:
    - `jobs=4`, `local_ram_resources=16384`, `local_cpu_resources=4`, `local_test_jobs=2`
- run artifacts:
  - status: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r93-20260225T071301Z.status`
  - log: `docs/s390x/logs/2026-02-25/proxy-docker-tests-r93-20260225T071301Z.log`
- outcome:
  - `rc=0`
  - wide sweep passed (`14/14 tests pass`)
  - Bazel server-abrupt crash from `r92` did not reproduce under moderate profile.

## Harness Stability Loop: `r99` failure and `r100` recovery

### Run `r99` (failed)

- status: `docs/s390x/logs/2026-02-25/s390x-harness-r99-20260225T071631Z.status`
- log: `docs/s390x/logs/2026-02-25/s390x-harness-r99-20260225T071631Z.log`
- outcome:
  - `rc=1`
  - smoke failed with:
    - `cluster-health` not reachable (`0/1`)
    - `host-to-pod-health` timeout to cilium-health endpoint.
- correlated cilium errors:
  - repeated node-manager route sync failures:
    - `failed to enable local node route: update ipv4 routes: failed to add aux route "10.244.0.0/24": invalid argument`
  - host interface state observed during failure:
    - `cilium_host`/`cilium_net` existed but had no IPv4 address.

### Remediation

- performed controlled datapath re-init:
  - `kubectl -n kube-system delete pod -l k8s-app=cilium`
  - `kubectl -n kube-system delete pod -l k8s-app=cilium-envoy`
  - waited for daemonset rollouts to complete.
- post-remediation verification:
  - `cilium_host` restored with IPv4:
    - `10.244.0.221/32`
  - local route restored:
    - `10.244.0.0/24 via 10.244.0.221 dev cilium_host`
  - `cilium-health status --verbose` returned:
    - `Cluster health: 1/1 reachable`.

### Run `r100` (passed)

- status: `docs/s390x/logs/2026-02-25/s390x-harness-r100-20260225T072524Z.status`
- log: `docs/s390x/logs/2026-02-25/s390x-harness-r100-20260225T072524Z.log`
- outcome:
  - `rc=0`
  - smoke passed
  - policy integration passed
  - BPF subset passed.

## CoreDNS environment note (non-blocking for harness path)

- manual `test/s390x/smoke_status.sh` run with default settings (`REQUIRE_COREDNS=true`, `HOST_TO_POD_TARGET=coredns`) failed due CoreDNS CrashLoopBackOff and no kube-dns ready endpoints.
- harness path remains stable with:
  - `REQUIRE_COREDNS=false`
  - `HOST_TO_POD_TARGET=cilium-health`.

## Strict CoreDNS Harness Loop on `kdz` (`r101` -> `r102`)

### Run `r101` (failed / terminated)

- status: `docs/s390x/logs/2026-02-25/s390x-harness-strict-r101-20260225T153956Z.status` (`rc=143`)
- log: `docs/s390x/logs/2026-02-25/s390x-harness-strict-r101-20260225T153956Z.log`
- launch profile:
  - `REQUIRE_COREDNS=true`
  - `HOST_TO_POD_TARGET=coredns`
  - `RUN_POLICY_INTEGRATION=true`
  - `RUN_BPF_REGRESSION_SUBSET=true`
- observed blocker:
  - deploy entered `ImagePullBackOff` for cilium daemonset image:
    - `docker.io/cilium/cilium-dev:1233512912-nogit-wip`
  - tag was not present in local CRI cache and not available from registry.
- impact:
  - rollout stalled before smoke/policy/BPF phases.

### Remediation: harness image-tag fallback for missing default tags

- file patched:
  - `test/s390x/deploy_cilium_s390x.sh`
- remediation behavior:
  - only when default image refs are in use (`cilium-dev:1233512912-nogit-wip` and default operator ref)
  - and only when those default refs are not present in CRI cache
  - discover first cached tag for same repo via `crictl images`
  - use cached tag for deployment and log the fallback decision.
- safety scope:
  - explicit user-provided image env vars remain authoritative.
  - change is isolated to `test/s390x` harness script path.

### Run `r102` (passed, strict mode)

- status: `docs/s390x/logs/2026-02-25/s390x-harness-strict-r102-20260225T154317Z.status` (`rc=0`)
- log: `docs/s390x/logs/2026-02-25/s390x-harness-strict-r102-20260225T154317Z.log`
- outcome:
  - strict CoreDNS smoke passed with `REQUIRE_COREDNS=true`.
  - policy integration passed.
  - BPF subset passed:
    - `tc_lxc_policy_drop`
    - `tc_policy_reject_response_test`
    - `hairpin_sctp_flow`
  - deploy path logged expected fallback:
    - `Default image docker.io/cilium/cilium-dev:1233512912-nogit-wip not cached; using docker.io/cilium/cilium-dev:s390x-be-policyfix2-20260221T163855Z`.

## Current checkpoint

- strict and non-strict harness profiles are both validated on `kdz`.
- next operational focus is local PR-slice preparation for upstreamable chunks (no upstream actions yet), plus continued repeated-run stability sweeps.

## Multi-control-plane bring-up and cross-node datapath validation (`kdz` + `zkd0`)

- cluster topology validated from both control-plane hosts:
  - `kdz.dev.fyre.ibm.com` (`10.14.125.157`)
  - `zkd01.fyre.ibm.com` (`10.11.59.172`)
  - both `Ready`, role `control-plane`, Kubernetes `v1.35.1`.
- Cilium daemonset state:
  - `2/2` pods ready across both nodes.
  - both agents now report `cilium-health status: 2/2 reachable`.

### Root cause isolated for BE cross-node breakage

- issue class:
  - architecture-dependent C bitfield layout in BPF `remote_endpoint_info` flags (`bpf/lib/eps.h`).
- failure mechanism on `s390x` (BE):
  - userspace writes low-bit masks into map fields (for example `has_tunnel` as `0x02`).
  - BPF bitfield read order on BE interpreted these masks with different semantic positions.
  - tunnel flag was effectively misread, causing remote endpoint/tunnel path decisions to fail and cross-node traffic to loop/fail.
- remediation implemented:
  - updated `bpf/lib/eps.h` to use endian-aware bitfield declaration order:
    - existing declaration retained on little-endian.
    - reversed declaration order on big-endian so runtime semantics align with userspace masks.
  - because full image rebuild path is currently constrained by missing s390x manifests for builder dependencies, remediation was validated via runtime BPF header override:
    - configmap mount into cilium-agent at `/var/lib/cilium/bpf/lib/eps.h`.

### Validation evidence after remediation

- cross-node matrix log:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-matrix-20260225T194416Z.log`
  - results:
    - same-node pod IP: pass (both nodes)
    - cross-node pod IP: pass (both directions)
    - cross-node service IP: pass (both directions)
    - cilium-health: `2/2 reachable` on both agents.
- smoke harness log:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-smoke-20260225T194244Z.log`
  - `REQUIRE_COREDNS=false HOST_TO_POD_TARGET=cilium-health` passed (`rc=0`).
- policy harness log:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-policy-20260225T194256Z.log`
  - policy allow/deny/allow flow passed (`rc=0`) with CEP convergence.

### Next action

- completed later in this journal via local image-integrated rollout (`cilium-dev-eps` alias image) and runtime override removal; remaining follow-up is to make this path fully reproducible without local retag/import workarounds.

## Harness codification: reusable multi-node datapath matrix script

- added `test/s390x/multinode_matrix.sh` to codify two-node datapath validation:
  - deploys pinned `agnhost` client/server pods on two explicit nodes,
  - validates same-node pod IP, cross-node pod IP, and cross-node service IP flows in both directions,
  - includes `cilium-health status` snapshot for both agents,
  - supports env-driven node/namespace/image/timeouts for regression loops.
- documented in `test/s390x/README.md`.
- execution evidence:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-matrix-script-20260225T194700Z.log` (`rc=0`).
- cleanup:
  - removed stale namespace `s390x-mn-191412`; active validation namespace is `s390x-crossnode`.

## High-value validation expansion and image-integrated remediation

### Added regression harnesses for multi-node behavior

- Added `test/s390x/multinode_policy_enforcement.sh`:
  - enforces cross-node placement (`client` and `server` on different nodes),
  - validates `allow -> deny -> allow` policy transitions with CEP convergence.
- Added `test/s390x/nodeport_crossnode.sh`:
  - deploys two-node server/client set plus hostNetwork probes,
  - validates cross-node NodePort and ClusterIP paths with retries (avoids startup-race false negatives).
- Both scripts were wired into `test/s390x/README.md`.

### Pre-image-integration validation (new harnesses)

- policy harness pass:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-policy-enforcement-20260225T195107Z.log`.
- nodeport harness pass:
  - `docs/s390x/logs/2026-02-25/kdz-nodeport-crossnode-script-20260225T195443Z.log`.

### Image-integrated BE fix path (runtime override removed)

- Built derived cilium image on `kdz` with baked `eps.h`:
  - `docker.io/cilium/cilium-dev:s390x-be-epsimg-20260225T195619Z`.
  - build log: `docs/s390x/logs/2026-02-25/kdz-cilium-epsimg-build-20260225T195617Z.log`.
- Imported derived image to `kdz` containerd and verified baked `eps.h` layer path:
  - `docs/s390x/logs/2026-02-25/kdz-cilium-epsimg-import-20260225T195646Z.log`.
- Direct cross-host tar stream to `zkd0` was aborted for throughput reasons:
  - `docs/s390x/logs/2026-02-25/kdz-to-zkd0-cilium-epsimg-seed-20260225T195736Z.log`.
- Built image on `zkd0`; direct import under original repo name hit archive collision:
  - `docs/s390x/logs/2026-02-25/zkd0-cilium-epsimg-build-import-20260225T200123Z.log`.
- Finalized by retag/import under distinct local repo alias on both nodes:
  - `docker.io/cilium/cilium-dev-eps:s390x-be-epsimg-20260225T195619Z`.

### Strict harness run with image-integrated tag

- Run:
  - `RUN_ID=r107 ... CILIUM_IMAGE_REPO=docker.io/cilium/cilium-dev-eps CILIUM_IMAGE_TAG=s390x-be-epsimg-20260225T195619Z ... ./test/s390x/launch_logged_run.sh`
- wrapper log:
  - `docs/s390x/logs/2026-02-25/kdz-harness-strict-epsimg-r107-20260225T200352Z.log`
- harness artifacts:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-25/s390x-harness-r107-20260225T200354Z.log`
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-25/s390x-harness-r107-20260225T200354Z.status`
- outcome:
  - `rc=0` (strict smoke + policy + BPF subset pass) using image-integrated cilium tag.

### Removal of runtime override path and post-image validation

- Removed manual runtime override mount from daemonset:
  - deleted `bpf-overrides` volume mount (`/var/lib/cilium/bpf/lib/eps.h`) and `bpf-overrides` volume from `ds/cilium`.
- Verified running cilium pods contain patched marker directly from image:
  - `grep __ORDER_LITTLE_ENDIAN__ /var/lib/cilium/bpf/lib/eps.h` returns expected marker.
- Post-rollout health:
  - immediate snapshot showed transient asymmetry,
  - after one probe interval, both agents converged to `2/2 reachable`.
- post-image matrix pass:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-matrix-postimg-20260225T200738Z.log`.
- post-image policy enforcement pass:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-policy-enforcement-postimg-20260225T200958Z.log`.
- post-image nodeport:
  - initial run hit expected env conflict (`32080` already allocated):
    - `docs/s390x/logs/2026-02-25/kdz-nodeport-crossnode-postimg-20260225T201047Z.log`.
  - rerun on free NodePort (`32081`) passed:
    - `docs/s390x/logs/2026-02-25/kdz-nodeport-crossnode-postimg-rerun-20260225T201105Z.log`.
- post-validation cleanup:
  - deleted temporary test namespaces (`s390x-crossnode*`, `s390x-nodeport*`, `s390x-policy-mn*`) to reset cluster state and prevent future resource collisions.
