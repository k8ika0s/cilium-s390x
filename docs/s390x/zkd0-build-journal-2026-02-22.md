# zkd0 s390x Build Journal

- Date: 2026-02-22
- Workspace: `cilium-s390x` (local clone)
- Branch: `k8ika0s/s390x-local-pr-stack`
- Last updated (UTC): `2026-02-23T03:40:37Z`

## Reporting and Log Hygiene Update

- Added `docs/s390x/README.md` for docs scope/rules.
- Added `docs/s390x/reporting-flow.md` for standardized run reporting flow.
- Added `docs/s390x/logs/README.md` for archive rules.
- Added `docs/s390x/logs/2026-02-22/RUN-INDEX.md` as daily run ledger.
- Path references in report docs are being normalized to repo-relative form.

## Daily Rollover

- Active daily log path: `docs/s390x/logs/2026-02-22/`
- Synced from remote:
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-22/proxy-docker-tests-r66-20260222T044758Z.log`
  - `docs/s390x/logs/2026-02-22/proxy-docker-tests-r66-20260222T044758Z.log`

## Proxy Stream Summary

### Baseline failure before current retries

- Run: `r65`
- Log: `docs/s390x/logs/2026-02-21/proxy-docker-tests-r65-20260221T231716Z.log`
- Result: failed near end of build (`clang-18` killed during compile).

### Resource-scoped remediation applied (s390x only)

- File: `../proxy-s390x/Makefile.docker`
- Change:
  - `EXTRA_BAZEL_BUILD_OPTS += --jobs=1 --local_ram_resources=2048 --local_cpu_resources=1`
  - `BAZEL_TEST_OPTS := --jobs=1 --local_ram_resources=2048 --local_cpu_resources=1 --test_timeout=300 --local_test_jobs=1 --flaky_test_attempts=3 --test_output=errors`

### Completed run

- Run: `r66`
- Command: `ARCH=s390x make docker-tests`
- Log: `docs/s390x/logs/2026-02-22/proxy-docker-tests-r66-20260222T044758Z.log`
- Result: build completed, failed in test execution stage.
- Failing targets:
  - `//tests:cilium_tls_http_integration_test`
  - `//tests:cilium_tls_tcp_integration_test`
  - `//tests:cilium_websocket_encap_integration_test`
  - `@envoy//test/integration:tcp_proxy_integration_test`
- Signature:
  - `Failed to load certificate chain ... upstreamlocalhostcert.pem`
  - `SSL error ... X.509 certificate routines ...`

### Run state update

- Run: `r68`
- Command: `ARCH=s390x make docker-tests`
- Remote log: `/root/work/cilium-s390x/docs/s390x/logs/2026-02-22/proxy-docker-tests-r68-20260222T230925Z.log`
- Status: `blocked` as of `2026-02-23T03:39:56Z`
- Variant under test: BoringSSL s390x target patch with `OPENSSL_BIGENDIAN` removed.
- Latest confirmed compile progress in log: around `[5,214 / 7,843]`.
- No active `make`, `podman`, or `bazel` processes detected at `2026-02-23T03:39:56Z`.
- Log stopped without terminal pass/fail footer:
  - no `Build completed`, `Build did NOT complete`, or final `make: ***` line
  - last log mtime: `2026-02-23T02:44:05Z`
- Current interpretation: run ended unexpectedly (likely wrapper/session interruption or abrupt termination before footer emission); outcome is not a valid completed result.

## Cross-References

- Daily run ledger: `docs/s390x/logs/2026-02-22/RUN-INDEX.md`
- Upstream draft tracker: `docs/s390x-upstream-issue-pr-drafts.md`
