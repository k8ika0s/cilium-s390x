# Run Index (2026-02-24)

All timestamps are UTC.

| Run | Component | Command | Status | Local Log | Remote Log | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `r75-carryover` | `proxy` | `make docker-tests ARCH=s390x CARGO_BAZEL_REPIN=true EXTRA_BAZEL_BUILD_OPTS=... BAZEL_TEST_OPTS=...` | `failed` | `docs/s390x/logs/2026-02-23/proxy-docker-tests-r75-20260223T213114Z.log` | `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r75-20260223T213114Z.log` | Overnight completion from prior day. `rc=2` at `2026-02-24T00:13:55Z`. Prior `r74` mount-path blocker is resolved; failure moved to test execution (TLS cert-chain load failures, IPv6 `[::1]` bind failures, websocket/tcp integration failures). |
| `status-roll-01` | `meta` | `kdz status + log triage` | `completed` | `n/a` | `kdz:/root/work/.../r75 log + status` | Morning roll completed. No active build processes. Runtime check shows IPv6 disabled on host (`net.ipv6.conf.*.disable_ipv6 = 1`), matching `[::1]` bind failures in IPv6 integration tests. Next action is targeted test remediation and narrowed reruns on `kdz`. |
| `runtime-fix-01` | `kdz-host` | `sysctl enable IPv6 + ensure ::1 on lo` | `completed` | `n/a` | `kdz host runtime` | Enabled `net.ipv6.conf.{all,default,lo}.disable_ipv6=0` and verified loopback `::1/128` present. This removes the known host-level blocker for `[::1]:0` binds in websocket IPv6 tests. |
| `r76` | `proxy` | `make docker-tests ARCH=s390x CARGO_BAZEL_REPIN=false TEST_TARGETS=...` | `failed` | `docs/s390x/logs/2026-02-24/proxy-docker-tests-r76-20260224T182540Z.log` | `/root/work/cilium-s390x/docs/s390x/logs/2026-02-24/proxy-docker-tests-r76-20260224T182540Z.log` | `rc=2` at `2026-02-24T18:26:15Z`. Failure is pre-test: Rust crate digest mismatch in `dynamic_modules_rust_sdk_crate_index` while `CARGO_BAZEL_REPIN=false`. No new TLS/websocket signal captured in this run. |
| `r77` | `proxy` | `make docker-tests ARCH=s390x CARGO_BAZEL_REPIN=true TEST_TARGETS=...` | `failed` | `docs/s390x/logs/2026-02-24/proxy-docker-tests-r77-20260224T182719Z.log` | `/root/work/cilium-s390x/docs/s390x/logs/2026-02-24/proxy-docker-tests-r77-20260224T182719Z.log` | `rc=2` at `2026-02-24T18:27:44Z`. Failure was patch application metadata: `boringssl_s390x.patch` hunk count mismatch (`Wrong chunk detected near line 15`). |
| `r78` | `proxy` | `make docker-tests ARCH=s390x CARGO_BAZEL_REPIN=true TEST_TARGETS=...` | `failed` | `docs/s390x/logs/2026-02-24/proxy-docker-tests-r78-20260224T182839Z.log` | `/root/work/cilium-s390x/docs/s390x/logs/2026-02-24/proxy-docker-tests-r78-20260224T182839Z.log` | `rc=2` at `2026-02-24T19:45:59Z`. Reached full test execution; all four targeted test targets failed across retries. TLS failures still show repeated PEM/X.509 load-chain errors for `upstreamlocalhostcert.pem`; websocket integration also failed (14/18 cases). |

## Current Focus

- Confirm root cause of TLS test cert-chain load failures (`upstreamlocalhostcert.pem`) in sandboxed test runfiles on s390x.
- Determine whether podman/netavark/container runtime configuration is suppressing IPv6 loopback (`[::1]:0`) for integration tests, and apply non-arch-breaking remediation.
- Triage websocket/tcp integration failures on IPv4 path after runtime/environment fixes.
- Determine why TLS cert-chain parsing still fails after BoringSSL `OPENSSL_BIG_ENDIAN` propagation (e.g. inspect PEM decoding path, cert bytes, and possible missing BoringSSL BE assumptions beyond target macro).
- Reduce websocket failure set by separating TLS-dependent websocket cases from transport/runtime cases now that host IPv6 is enabled.
- Keep subsequent build/perf/test runs on `kdz` and preserve upstreamable change slices.
