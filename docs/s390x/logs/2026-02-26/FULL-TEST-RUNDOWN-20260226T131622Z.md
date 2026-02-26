# Full Build/Integration Rundown (2026-02-26T13:16:22Z UTC)

Host: kdz.dev.fyre.ibm.com
Workspace: /root/work/cilium-s390x
Log dir: /root/work/cilium-s390x/docs/s390x/logs/2026-02-26

| Test | Status | RC | Log | Notes |
| --- | --- | --- | --- | --- |
| go-regression-packages | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-go-regression-20260226T131809Z.log | Targeted Go regression packages |
| proxy-docker-tests-wide | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-proxy-docker-tests-wide-20260226T131809Z.log | Mirror of previous r93 mid-profile wide sweep |
| s390x-harness-strict-image-integrated | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-harness-strict-image-integrated-20260226T131809Z.wrapper.log | Runs smoke+policy+bpf via launch_logged_run |
| s390x-integration-wide | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-integration-wide-20260226T131809Z.wrapper.log | Broad go test ./... sweep |
| multinode-matrix | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-multinode-matrix-20260226T131809Z.log | Pod/service same-node + cross-node matrix |
| multinode-policy-enforcement | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-multinode-policy-20260226T131809Z.log | Baseline allow -> deny -> allow |
| nodeport-crossnode | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-nodeport-crossnode-20260226T131809Z.log | NodePort selected dynamically: 32080 |

## Totals

- PASS: 7
- FAIL: 0
| go-regression-packages-nocache | PASS | 0 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-go-regression-nocache-20260226T132310Z.log | Forced execution via -count=1 |
| proxy-docker-tests-wide-nocache | FAIL | 2 | /root/work/cilium-s390x/docs/s390x/logs/2026-02-26/full-proxy-docker-tests-wide-nocache-20260226T132310Z.log | Forced execution via NO_CACHE=1 + --cache_test_results=no |
