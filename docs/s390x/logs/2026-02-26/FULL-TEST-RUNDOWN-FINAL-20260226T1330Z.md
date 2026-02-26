# Full Build/Integration Rundown (kdz, 2026-02-26 UTC)

Host: kdz.dev.fyre.ibm.com  
Workspace: /root/work/cilium-s390x  
Local sync: /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26

## Primary Full Suite (Requested Coverage)

| Test | Status | RC | Log | Notes |
| --- | --- | --- | --- | --- |
| go-regression-packages | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-go-regression-20260226T131809Z.log | Targeted Go regression packages |
| proxy-docker-tests-wide | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-proxy-docker-tests-wide-20260226T131809Z.log | Wide proxy build/test sweep (cache-hit run) |
| s390x-harness-strict-image-integrated | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-harness-strict-image-integrated-20260226T131809Z.wrapper.log | Strict smoke+policy+bpf using image-integrated tag |
| s390x-integration-wide | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-integration-wide-20260226T131809Z.wrapper.log | Broad integration-wide go test sweep |
| multinode-matrix | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-multinode-matrix-20260226T131809Z.log | Cross-node pod/service matrix |
| multinode-policy-enforcement | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-multinode-policy-20260226T131809Z.log | Baseline allow -> deny -> allow |
| nodeport-crossnode | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-nodeport-crossnode-20260226T131809Z.log | NodePort + hostnet cross-node checks |

Primary suite totals: PASS 7, FAIL 0.

## Additional Verification Runs

| Test | Status | RC | Log | Notes |
| --- | --- | --- | --- | --- |
| go-regression-packages-nocache | PASS | 0 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-go-regression-nocache-20260226T132310Z.log | Forced execution (`go test -count=1`) |
| proxy-docker-tests-wide-nocache | FAIL | 2 | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-proxy-docker-tests-wide-nocache-20260226T132310Z.log | Failed while clearing mounted cache (`Permission denied` in `rm -rf /cilium/proxy/.cache/*`) |
| proxy-docker-tests-wide-forcedexec | ABORTED | n/a | /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/docs/s390x/logs/2026-02-26/full-proxy-docker-tests-wide-forcedexec-20260226T132533Z.log | Started with `--cache_test_results=no --runs_per_test=2`; manually terminated to avoid long cold-rebuild cycle |

Additional run totals: PASS 1, FAIL 1, ABORTED 1.
