# Run Index (2026-02-22)

All timestamps are UTC.

| Run | Component | Command | Status | Local Log | Remote Log | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `r66` | `proxy` | `ARCH=s390x make docker-tests` | `failed` | `docs/s390x/logs/2026-02-22/proxy-docker-tests-r66-20260222T044758Z.log` | `/root/work/cilium-s390x/docs/s390x/logs/2026-02-22/proxy-docker-tests-r66-20260222T044758Z.log` | Build completed; 4 TLS/integration tests failed (cert chain load errors). |
| `r68` | `proxy` | `ARCH=s390x make docker-tests` | `blocked` | `docs/s390x/logs/2026-02-22/proxy-docker-tests-r68-20260222T230925Z.log` | `/root/work/cilium-s390x/docs/s390x/logs/2026-02-22/proxy-docker-tests-r68-20260222T230925Z.log` | Run terminated without final pass/fail footer. Last observed progress around `[5,214 / 7,843]`; log mtime `2026-02-23T02:44:05Z`; no active `make/podman/bazel` by `2026-02-23T03:39:56Z`. |

## Current Focus

- Determine why `r68` exited without terminal markers (wrapper/session interruption vs external kill).
- Relaunch proxy docker-tests with resilient logging (`nohup` + explicit exit-code capture) before next remediation conclusion.
