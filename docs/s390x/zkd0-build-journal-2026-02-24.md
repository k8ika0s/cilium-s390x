# zkd0 s390x Build Journal

- Date: `2026-02-24` (UTC)
- Active execution host for heavy runs: `kdz` (`RHEL 9.6`, `s390x`, big-endian)
- Scope for this day: roll logs, capture overnight completion state, and drive targeted test remediation planning.

## Overnight Carryover Result (`r75`)

- Source run:
  - log: `docs/s390x/logs/2026-02-23/proxy-docker-tests-r75-20260223T213114Z.log`
  - status: `docs/s390x/logs/2026-02-23/proxy-docker-tests-r75-20260223T213114Z.status`
- Completion:
  - `rc=2`
  - `ended_at=2026-02-24T00:13:55Z`
- Outcome classification:
  - `r74` late-stage mount-source failure is remediated.
  - `r75` reached runner test execution and failed in test targets.

## Failure Snapshot (`r75`)

- Failing targets:
  - `//tests:cilium_tls_http_integration_test`
  - `//tests:cilium_tls_tcp_integration_test`
  - `//tests:cilium_websocket_encap_integration_test`
  - `@envoy//test/integration:tcp_proxy_integration_test`
- Dominant signatures in logs:
  - TLS tests:
    - repeated `Failed to load certificate chain ... upstreamlocalhostcert.pem`
  - websocket IPv6 tests:
    - repeated `cannot bind '[::1]:0': Cannot assign requested address`
  - websocket IPv4 path:
    - write/flush instability with broken-pipe/unexpected disconnect failures.

## Morning Check-In (`2026-02-24`)

- Verified remote time/host parity and completion status on `kdz`.
- Confirmed no active `make docker-tests`/bazel build processes remain from `r75`.
- Captured runtime-network baseline on `kdz`:
  - `net.ipv6.conf.all.disable_ipv6 = 1`
  - `net.ipv6.conf.default.disable_ipv6 = 1`
  - `net.ipv6.conf.lo.disable_ipv6 = 1`
  - container network backend: `netavark`
  - this aligns with observed test failures binding `[::1]:0` in IPv6 websocket cases.
- Updated historical ledger files for `2026-02-23` with final `r75` disposition.
- Rolled daily run index:
  - `docs/s390x/logs/2026-02-24/RUN-INDEX.md`

## Runtime Remediation Applied (`kdz`)

- Enabled host IPv6 loopback path (to remove known `[::1]:0` bind blocker from websocket integration tests):
  - `sysctl -w net.ipv6.conf.all.disable_ipv6=0`
  - `sysctl -w net.ipv6.conf.default.disable_ipv6=0`
  - `sysctl -w net.ipv6.conf.lo.disable_ipv6=0`
  - ensured loopback includes `::1/128`
- Post-change verification:
  - `net.ipv6.conf.all.disable_ipv6 = 0`
  - `net.ipv6.conf.default.disable_ipv6 = 0`
  - `net.ipv6.conf.lo.disable_ipv6 = 0`
  - `ip -6 addr show lo` includes `::1/128`

## Code Remediation Launched (`r76`)

- Updated downstream BoringSSL s390x target patch to propagate explicit big-endian macro:
  - file: `proxy-s390x/patches/0008-bazel-Wire-boringssl-s390x-target-patch.patch`
  - change: add `#define OPENSSL_BIG_ENDIAN` under `__s390x__ && __linux__`
  - intent: prevent implicit little-endian behavior in crypto internals on s390x BE.
- Started new targeted run:
  - run id: `r76`
  - start: `2026-02-24T18:25:40Z`
  - log: `docs/s390x/logs/2026-02-24/proxy-docker-tests-r76-20260224T182540Z.log`
  - status: `docs/s390x/logs/2026-02-24/proxy-docker-tests-r76-20260224T182540Z.status`
  - command class: `make docker-tests ARCH=s390x ...`
  - targeted test set:
    - `//tests:cilium_tls_http_integration_test`
    - `//tests:cilium_tls_tcp_integration_test`
    - `//tests:cilium_websocket_encap_integration_test`
    - `@envoy//test/integration:tcp_proxy_integration_test`

## `r76` Fast-Fail and `r77` Relaunch

- `r76` completed quickly with `rc=2` at `2026-02-24T18:26:15Z`.
- Failure class was not TLS/websocket execution yet:
  - Bazel/rules_rust fetch failed for `dynamic_modules_rust_sdk_crate_index` with digest mismatch.
  - Trigger condition: `CARGO_BAZEL_REPIN=false`.
  - Message recommends rerun with `CARGO_BAZEL_REPIN=true`.
- Immediate remediation:
  - launched `r77` at `2026-02-24T18:27:19Z` with identical test targets and `CARGO_BAZEL_REPIN=true`.
  - `r77` log: `docs/s390x/logs/2026-02-24/proxy-docker-tests-r77-20260224T182719Z.log`
  - `r77` status: `docs/s390x/logs/2026-02-24/proxy-docker-tests-r77-20260224T182719Z.status`

## `r77` Patch-Metadata Failure and `r78` Relaunch

- `r77` ended `rc=2` at `2026-02-24T18:27:44Z`.
- Failure class:
  - bazel fetch of `@boringssl` failed while applying `boringssl_s390x.patch`.
  - explicit error: `Wrong chunk detected near line 15`.
  - cause: inner hunk header in downstream patch did not match added line count.
- Remediation:
  - updated local downstream patch header from `@@ -53,6 +53,10 @@` to `@@ -53,6 +53,11 @@`.
  - synced corrected patch to `kdz` and relaunched as `r78`.
- `r78` metadata:
  - start: `2026-02-24T18:28:39Z`
  - log: `docs/s390x/logs/2026-02-24/proxy-docker-tests-r78-20260224T182839Z.log`
  - status: `docs/s390x/logs/2026-02-24/proxy-docker-tests-r78-20260224T182839Z.status`
  - early progress confirms patch application now succeeds; build advanced into BoringSSL compile (`crypto/fipsmodule/bcm.cc`).

## `r78` Final Outcome

- Completion:
  - `rc=2`
  - `ended_at=2026-02-24T19:45:59Z`
- Coverage:
  - run completed full targeted build + test stage (`4` test targets executed, each retried `3` times).
- Failing targets:
  - `//tests:cilium_tls_http_integration_test`
  - `//tests:cilium_tls_tcp_integration_test`
  - `//tests:cilium_websocket_encap_integration_test`
  - `@envoy//test/integration:tcp_proxy_integration_test`
- Dominant signatures:
  - TLS remains blocked with repeated:
    - `SSL error ... X.509 certificate routines ...`
    - `SSL error ... PEM routines ...`
    - `Failed to load certificate chain ... upstreamlocalhostcert.pem`
  - websocket suite still fails broadly (`14 FAILED TESTS` in run summary), indicating additional issues beyond host IPv6 disablement.
- Interpretation:
  - BoringSSL patch now applies and build proceeds, but adding `OPENSSL_BIG_ENDIAN` alone did not resolve TLS certificate-chain load failures on s390x.

## Remaining Work

- Isolate cert-chain load failures:
  - verify runfiles cert presence/permissions/path correctness in test sandbox.
  - compare with known-good non-s390x path to determine whether issue is pathing/runtime packaging vs crypto handling.
- Isolate IPv6 bind failures:
  - validate loopback IPv6 availability inside podman build/test environment.
  - remediate runtime/network config without introducing architecture-specific behavior that affects other targets.
- Re-run targeted tests first, then full `docker-tests`:
  - `//tests:cilium_tls_http_integration_test`
  - `//tests:cilium_tls_tcp_integration_test`
  - `//tests:cilium_websocket_encap_integration_test`
  - `@envoy//test/integration:tcp_proxy_integration_test`
