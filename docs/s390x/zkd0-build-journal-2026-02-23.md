# zkd0 s390x Build Journal

- Date: 2026-02-23
- Workspace: `cilium-s390x` (local clone)
- Branch: `k8ika0s/s390x-local-pr-stack`
- HEAD: `faa3c8ffa7`
- Last updated (UTC): `2026-02-23T18:26:17Z`

## Rollover Notes

- Prior day run `r68` was marked `blocked` after stopping without terminal footer.
- `r68` log synced locally:
  - `docs/s390x/logs/2026-02-22/proxy-docker-tests-r68-20260222T230925Z.log`
- 2026-02-22 ledger updated:
  - `docs/s390x/logs/2026-02-22/RUN-INDEX.md`

## Runtime Escalation

`r69` was canceled due poor feedback latency (hours of compile progression with no terminal status file) and replaced by `r70` using a speed-tuned s390x iteration profile.

## Speed Remediation Applied

- Synced to `/root/work/proxy-s390x` and kept local in `../proxy-s390x`:
  - `Makefile`
  - `Makefile.docker`
  - `Dockerfile.tests`
- Changes:
  - add configurable `CARGO_BAZEL_REPIN` and `TEST_TARGETS` in `Makefile`.
  - keep default behavior unchanged for non-s390x (`CARGO_BAZEL_REPIN=true`, full test scope).
  - on `ARCH=s390x` in `Makefile.docker`, default to:
    - `CARGO_BAZEL_REPIN=false`
    - `TEST_TARGETS=//tests:cilium_tls_http_integration_test //tests:cilium_tls_tcp_integration_test //tests:cilium_websocket_encap_integration_test @envoy//test/integration:tcp_proxy_integration_test`
  - pass both knobs through docker build args into `Dockerfile.tests` stages.
  - fix s390x override handling to honor both command-line and environment-origin values (not only command-line origin) for `CARGO_BAZEL_REPIN` and `TEST_TARGETS`.
  - extend the same override-origin fix pattern for s390x resource knobs:
    - `EXTRA_BAZEL_BUILD_OPTS`
    - `BAZEL_TEST_OPTS`
    so environment-based tuning can be applied without editing files between runs.
  - add persistent BuildKit cache mounts in `Dockerfile.tests` `builder-fresh` stage for:
    - `/cilium/proxy/.cache`
    - `/tmp/bazel-cache`
    to improve reuse across interrupted/failed runs.

## Attempts

### `proxy docker-tests` run `r69`

- Start time: `2026-02-23T03:43:28Z`
- Command: `ARCH=s390x make docker-tests`
- Remote launcher: `/root/work/proxy-r69-docker-tests.sh`
- Detached execution: `nohup /root/work/proxy-r69-docker-tests.sh ... &`
- PID at launch: `506046`

### Logging/Status Capture Hardening

- Primary log:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r69-20260223T034328Z.log`
- Status file (written only on terminal completion):
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r69-20260223T034328Z.status`
- Final state:
  - status file absent (`.status` never written)
  - run canceled and superseded by `r70`
  - local log synced: `docs/s390x/logs/2026-02-23/proxy-docker-tests-r69-20260223T034328Z.log`

### Observed Log Preamble (r69)

- `git_rev=9e7e35f1`
- s390x patch marker in log:
  - `__s390x__`
  - `OPENSSL_ASM_INCOMPATIBLE`
  - no `OPENSSL_BIGENDIAN`

### `proxy docker-tests` run `r70`

- Start time: `2026-02-23T15:21:24Z`
- Command: `ARCH=s390x make docker-tests`
- Remote launcher: `/root/work/proxy-r70-docker-tests.sh`
- Detached execution: `nohup /root/work/proxy-r70-docker-tests.sh ... &`
- PID at launch: `1067340`
- Primary log:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r70-20260223T152124Z.log`
- Status file (on completion):
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r70-20260223T152124Z.status`
- Outcome:
  - failed fast (`rc=2`) due rust lock/digest mismatch in `dynamic_modules_rust_sdk_crate_index`
  - explicit remediation required: `CARGO_BAZEL_REPIN=true`

### `proxy docker-tests` run `r71`

- Start time: `2026-02-23T15:23:37Z`
- Command: `CARGO_BAZEL_REPIN=true ARCH=s390x make docker-tests`
- Primary log:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r71-20260223T152337Z.log`
- Outcome:
  - canceled after identifying override bug in `Makefile.docker`:
    - environment-origin `CARGO_BAZEL_REPIN=true` was ignored
    - effective docker build arg remained `CARGO_BAZEL_REPIN=false`

### `proxy docker-tests` run `r72`

- Start time: `2026-02-23T15:24:21Z`
- Command: `CARGO_BAZEL_REPIN=true ARCH=s390x make docker-tests`
- Primary log:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r72-20260223T152421Z.log`
- Status file (on completion):
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r72-20260223T152421Z.status`
- Outcome:
  - progressed through analysis/compile, then stayed in one long `rules_foreign_cc` action with outer counter fixed at `1114/5177`
  - heartbeat for that action advanced to `1241s`
  - canceled at cutoff to avoid further unbounded wall-clock burn and replaced by tuned retries

### `proxy docker-tests` run `r73`

- Start time: `2026-02-23T15:59:25Z`
- Command: `ARCH=s390x CARGO_BAZEL_REPIN=true EXTRA_BAZEL_BUILD_OPTS=... BAZEL_TEST_OPTS=... make docker-tests`
- Primary log:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r73-20260223T155925Z.log`
- Outcome:
  - started successfully with cache-mount-enabled Dockerfile
  - canceled early because tuning did not propagate (docker build args still showed `--jobs=1 --local_ram_resources=2048 --local_cpu_resources=1`)
  - superseded by `r74` using explicit make command-line variable overrides

### `proxy docker-tests` run `r74`

- Start time: `2026-02-23T16:00:12Z`
- Command:
  - `make docker-tests ARCH=s390x CARGO_BAZEL_REPIN=true EXTRA_BAZEL_BUILD_OPTS="--jobs=2 --local_ram_resources=4096 --local_cpu_resources=2" BAZEL_TEST_OPTS="--jobs=2 --local_ram_resources=4096 --local_cpu_resources=2 --test_timeout=300 --local_test_jobs=2 --flaky_test_attempts=3 --test_output=errors"`
- Primary log:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r74-20260223T160012Z.log`
- Status file (on completion):
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r74-20260223T160012Z.status`
- Outcome:
  - completed at `2026-02-23T20:28:31Z` with `rc=2`
  - tuned settings were active throughout build (`--jobs=2 --local_ram_resources=4096 --local_cpu_resources=2`)
  - Bazel phase succeeded:
    - `INFO: Build completed successfully, 4512 total actions`
  - failure occurred in Dockerfile.tests runner `STEP 17` before `make envoy-tests` execution:
    - bind mount source from `archive-cache` stage missing:
      - `source=/tmp/bazel-cache,from=archive-cache`
      - error: `no such file or directory`
  - immediate implication:
    - failure is in Docker cache-mount plumbing, not Envoy/Cilium test compile logic.

## Connectivity Note

- At `2026-02-23T15:34:36Z`, polling was interrupted by transient loss of `zkd0` reachability:
  - `Read from remote host ...: No route to host`
  - `client_loop: send disconnect: Broken pipe`
- Reconnected by `2026-02-23T15:34:59Z` and resumed live polling.
- Post-reconnect observed progress:
  - `r72` advanced from `628/5177` to `961/5177` compile actions.
- Follow-on:
  - another brief connection drop occurred during live polling, then session resumed successfully.
  - active polling now tracks `r74`.

## Performance Snapshot

- Host capacity snapshot during `r72`:
  - `nproc=8`
  - `MemTotal≈15.8GiB`, `MemAvailable≈8.3GiB`
  - `SwapTotal=0` (no swap configured)
- `r72` throughput sample (60s window after reconnect):
  - progress `1073 -> 1114` of `5177`
  - rate `~0.68 actions/sec`
- Implication:
  - current conservative Bazel limits (`--local_ram_resources=2048 --local_cpu_resources=1`) are stable but materially increase wall-clock time.
  - perceived "hangs" can be single long-running `rules_foreign_cc` wrapper actions that compile many files internally before emitting the next outer Bazel action count.
- Active example captured in `r72`:
  - `processwrapper-sandbox/475` running `cmake_src/bootstrap`
  - nested `clang-18` compiles like `cmGlobalGenerator.cxx`
  - outer counter remained at `1114/5177` while this internal compile batch executed
  - observed heartbeat progression on same outer action: `401s -> 581s -> 701s -> 761s`
- Operational guardrail:
  - keep `r72` alive while heartbeat keeps advancing.
  - if heartbeat exceeds practical cutoff without clearing outer action, cancel and relaunch as `r73` with tuned resource flags and newly added persistent cache mounts.
  - this guardrail triggered; `r72` was canceled and replaced by `r73`, then `r74` for enforced tuning.
- `r74` early throughput sample (60s window):
  - progress `870 -> 958` of `5177`
  - rate `~1.47 actions/sec`
  - relative improvement vs `r72` sampled `~0.68 actions/sec`: about `2.16x`
- `r74` follow-up throughput sample (90s window):
  - progress `1035 -> 1157` of `5177`
  - rate `~1.35 actions/sec`
  - indicates sustained improvement through foreign_cc/gperftools phase (not only initial cache-heavy burst)
- `r74` second follow-up throughput sample (90s window):
  - progress `1216 -> 1345` of `5177`
  - rate `~1.43 actions/sec`
  - confirms continued throughput stability after passing the earlier `r72` choke point.
- `r74` third follow-up throughput sample (120s window):
  - progress `1377 -> 1494` of `5177`
  - rate `~0.97 actions/sec`
  - still materially faster than `r72` baseline while entering heavier SSL/OpenSSL compilation units.
- `r74` extended mid-run check (~180s):
  - progress advanced to `1713/5177` with no status file yet
  - `Foreign Cc - Configure: Building cmake_tool_default` shows steady counter movement (`1671 -> 1713`) instead of the prior `r72` single-action plateau
  - indicates the prior choke behavior is mitigated under current tuning/cache configuration.
- `r74` later status check:
  - encountered another long `cmake_tool_default` segment around `1863/5177`, then exited that phase and resumed broader compile flow
  - advanced to `3353/5177` on follow-up probe (`+24` actions over 40s)
  - no terminal status file yet; build remained active.
- `r74` newer status check:
  - advanced to `4875/5177` with continued compile churn and no terminal `.status` file yet
  - confirms sustained forward motion late in the action graph while `kdz` provisioning proceeds in parallel.
- `r74` completion check:
  - reached `5176/5177` and then wrote status file:
    - `rc=2`
    - `ended_at=2026-02-23T20:28:31Z`
  - failure root cause is post-build Docker mount resolution (`/tmp/bazel-cache` missing in `archive-cache` stage), not a compile/test assertion failure.

## Alternate Host Check (`kdz`)

- Connectivity and platform:
  - reachable via SSH
  - `RHEL 9.6 (Plow)`, `s390x`, big-endian (OS parity with `zkd0`)
- Capacity snapshot:
  - `16` vCPU (vs `8` on `zkd0`)
  - `~61 GiB` RAM, `~59 GiB` available (vs `~15.8 GiB` total on `zkd0`)
  - root disk `232G` with `~228G` free (vs `~6.7G` free on `zkd0`)
  - load average near idle (`0.00, 0.00, 0.00` at check time)
- Build prerequisites:
  - present: `gcc/g++`, `git`, `make`, `rsync`, `python3`, `dnf/yum`, root access
  - missing: `podman/docker/buildah`, `bazel/bazelisk`, `clang-18`, `go`
- Network egress checks:
  - `quay.io` reachable
  - `github.com` reachable
- Assessment:
  - hardware/storage profile on `kdz` is materially better for these builds.
  - migration is viable but requires one-time toolchain/bootstrap install plus rsync of repo and caches.

## Cross-References

- Daily run ledger: `docs/s390x/logs/2026-02-23/RUN-INDEX.md`
- Reporting flow: `docs/s390x/reporting-flow.md`
- Upstream draft tracker: `docs/s390x-upstream-issue-pr-drafts.md`

## `kdz` Provisioning And Migration Prep (Live While `r74` Runs)

- Time window (UTC):
  - bootstrap start: `2026-02-23T18:33Z`
  - sync/prep pass: `2026-02-23T18:40Z` onward
- tmux:
  - connected/created `kdz:cilium`
  - primary command pane: `%0`
  - live monitor pane: `%1` (`uptime/free/df` loop every 30s)

### `kdz` Host Baseline (confirmed)

- OS/arch: `RHEL 9.6 (Plow)`, `s390x`, big-endian.
- Capacity:
  - CPU: `16`
  - RAM: `~61 GiB` total (`~59 GiB` available at check)
  - root disk: `232G` with `~225-227G` free
- Tooling installed for parity:
  - `podman`, `buildah`, `fuse-overlayfs`, `slirp4netns`
  - `clang` (`20.1.8`), `go` (`1.25.7`), `git`, `make`, `rsync`, `python3`
  - `/root/bin/docker` wrapper added (`exec podman "$@"`)

### Repos/Artifacts Synced (`zkd0` -> `kdz`)

- Repositories copied to `/root/work`:
  - `cilium-s390x`, `proxy-s390x`, `image-tools-s390x`, `envoy-s390x`, `hubble-ui-s390x`, `certgen-s390x`, `ztunnel-s390x`
- Additional helpers copied:
  - `runtime-bootstrap`, `tools`
  - `proxy-r69`..`proxy-r74` docker test scripts
- Sync method:
  - streamed `tar` over SSH (no local staging on workstation)
  - excluded transient build outputs where applicable (`out/`, `target/`, `.cache/`, `node_modules/`, `.venv`)
- Post-sync ownership fix:
  - all synced trees were `uid:gid 501:20`; corrected to `root:root` on `kdz` to avoid Git "dubious ownership" failures.

### Dry-Run Verification On `kdz`

- In `/root/work/proxy-s390x`, `make -n docker-tests ARCH=s390x` succeeds and emits expected `docker buildx` command with:
  - `BUILDER_BASE=quay.io/cilium/cilium-envoy-builder:f896ec9cc6f0fc9524b041a1f0f3af93ec735609`
  - `PROXYLIB_BUILDER` set to same tag

### New Blocker Found During `kdz` Prep

- Direct pull on `kdz` fails:
  - `podman pull quay.io/cilium/cilium-envoy-builder:f896...`
  - error: no `linux/s390x` image in manifest list for that tag.
- Observation:
  - `zkd0` has a local image tagged as:
    - `quay.io/cilium/cilium-envoy-builder:f896ec9cc6f0fc9524b041a1f0f3af93ec735609`
    - image ID `32bebad05650`, size `~3.96GB`
- Remediation completed:
  - local image streamed from `zkd0` to `kdz` via:
    - `podman save ... | podman load`
  - resulting local tag on `kdz`:
    - `quay.io/cilium/cilium-envoy-builder:f896ec9cc6f0fc9524b041a1f0f3af93ec735609`
    - image ID `32bebad05650`

### Notes

- `zkd0 r74` ran to completion while provisioning work proceeded in parallel.
- Repeated SSH forwarding warnings (`Could not request local forwarding`) are noisy but non-blocking for command execution.
- `kdz -> zkd0` direct SSH is not currently usable for unattended copy orchestration:
  - short alias `zkd0` does not resolve on `kdz`
  - FQDN host key can be added, but auth fails (`Permission denied (publickey,...)`)
  - implication: cross-host artifact transfer still needs local workstation as orchestrator unless we add appropriate key material on `kdz`.

## `proxy docker-tests` Run `r75` (`kdz`)

- Start time (UTC): `2026-02-23T21:31:14Z`
- Host: `kdz` (`RHEL 9.6`, `s390x`, big-endian)
- Trigger:
  - patched `/root/work/proxy-s390x/Dockerfile.tests` to add `RUN mkdir -p /tmp/bazel-cache` in `builder-fresh`
  - objective: ensure `/tmp/bazel-cache` exists in default `archive-cache` source image to avoid the `r74` late-stage bind-mount failure
- Remote launcher: `/root/work/proxy-r75-docker-tests.sh`
- Detached execution:
  - `nohup /root/work/proxy-r75-docker-tests.sh /root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r75-20260223T213114Z.log /root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r75-20260223T213114Z.status &`
- Command:
  - `make docker-tests ARCH=s390x CARGO_BAZEL_REPIN=true EXTRA_BAZEL_BUILD_OPTS="--jobs=2 --local_ram_resources=4096 --local_cpu_resources=2" BAZEL_TEST_OPTS="--jobs=2 --local_ram_resources=4096 --local_cpu_resources=2 --test_timeout=300 --local_test_jobs=2 --flaky_test_attempts=3 --test_output=errors"`
- Early status:
  - run is active (`pid=86003` launcher, `pid=86006` make)
  - status file not yet present (expected while build is in progress)
  - log confirms progression into `proxylib` build (`STEP 5/5`) with tuned build args propagated.
- Progress samples (UTC):
  - `2026-02-23T21:33:17Z`: `[425 / 5,177]`
  - `2026-02-23T21:34:17Z`: `[873 / 5,177]`
  - `2026-02-23T21:36:45Z`: `[1,278 / 5,177]`
  - `2026-02-23T21:40:30Z`: `[1,566 / 5,177]`
  - `2026-02-23T21:43:17Z`: `[1,697 / 5,177]`
  - `2026-02-23T21:46:17Z`: `[1,863 / 5,177]`
- Stage status:
  - still in `builder-fresh` dependency step:
    - `[2/8] STEP 16/16 ... make envoy-test-deps`
  - this matches previous long-running foreign_cc/cmake spans seen in earlier runs, but with continued forward movement.
- Current check (`~2026-02-23T21:48Z`):
  - action counter has temporarily held at `[1,863 / 5,177]`, while process inspection shows active `cmake`/`make` compilation subprocesses under bazel sandbox.
  - interpretation: no terminal failure yet; still active in a long native build subtree.
- Follow-up liveness check (`~2026-02-23T21:58Z`):
  - action counter remains `[1,863 / 5,177]`, but the active subtarget under `cmake_tool_default` is changing (`CTestLib` -> `CPackLib`) and new `clang-18` compile subprocesses continue to appear.
  - decision: treat as slow-but-live (not deadlocked); continue run without cancellation to preserve chance of reaching the `r74` late-stage mount-failure boundary.
- Resume confirmation (`~2026-02-23T22:00Z`):
  - counter advanced past the long plateau:
    - `[1,864 / 5,177]` then `[1,867 / 5,177]`
  - phase transitioned from `Foreign Cc - Configure: Building cmake_tool_default` to `Foreign Cc - CMake: Building event`.
  - validates prior decision to keep run alive through the long configure window.
- Latest checkpoint (`2026-02-23T22:01:03Z`):
  - `r75` remains active with `.status` still pending.
  - counter advanced to `[1,882 / 5,177]` with ongoing protobuf/tool compile actions.
- Final outcome (`2026-02-24T00:13:55Z`, UTC):
  - status file written:
    - `rc=2`
    - `ended_at=2026-02-24T00:13:55Z`
  - key result:
    - previously blocking mount-source error from `r74` did not recur.
    - run completed compile/build phases and failed during test execution (`make envoy-tests` in runner stage).
  - failing targets (all 3 attempts each):
    - `//tests:cilium_tls_http_integration_test`
    - `//tests:cilium_tls_tcp_integration_test`
    - `//tests:cilium_websocket_encap_integration_test`
    - `@envoy//test/integration:tcp_proxy_integration_test`
  - dominant failure signatures observed in `r75` log:
    - TLS tests: repeated `Failed to load certificate chain ... upstreamlocalhostcert.pem`
    - websocket IPv6 tests: `cannot bind '[::1]:0': Cannot assign requested address`
    - websocket IPv4 path includes upstream flush/write disconnect regressions (`Broken pipe` / unexpected disconnect)
  - interpretation:
    - container-build compatibility blocker is remediated.
    - remaining blockers are runtime/integration-test issues requiring targeted investigation (test environment/runtime wiring and potential BE/runtime behavior deltas).
