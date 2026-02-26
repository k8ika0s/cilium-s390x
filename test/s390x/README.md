# s390x Runtime Harness

This directory contains a minimal runtime harness for validating Cilium on
Linux `s390x` clusters.

## Scope

- Deploy Cilium from local chart with explicit s390x image overrides.
- Run smoke checks for node and Cilium control-plane readiness.
- Collect logs and diagnostics for triage and regression tracking.

## Entry Points

- `test/s390x/deploy_cilium_s390x.sh`
- `test/s390x/smoke_status.sh`
- `test/s390x/policy_integration.sh`
- `test/s390x/multinode_matrix.sh`
- `test/s390x/multinode_policy_enforcement.sh`
- `test/s390x/nodeport_crossnode.sh`
- `test/s390x/bpf_regression_subset.sh`
- `test/s390x/integration_wide.sh`
- `test/s390x/collect_artifacts.sh`
- `test/s390x/run_harness.sh`
- `test/s390x/launch_logged_run.sh`

## Typical Flow

```bash
test/s390x/deploy_cilium_s390x.sh
test/s390x/smoke_status.sh
test/s390x/policy_integration.sh
test/s390x/bpf_regression_subset.sh
test/s390x/collect_artifacts.sh
```

## Host Prerequisites

- `python3` must be available on the host.
- For `bpf_regression_subset.sh`, Python modules `jinja2` and `scapy` are required.
  - RHEL/Fedora: `dnf install -y python3-jinja2 python3-scapy`
  - Debian/Ubuntu: `apt-get install -y python3-jinja2 python3-scapy`

Or run the full flow:

```bash
test/s390x/run_harness.sh
```

To run the full flow with structured log/status artifacts under
`docs/s390x/logs/<UTC date>/`:

```bash
RUN_ID=rNN test/s390x/launch_logged_run.sh
```

For wider Go integration sweeps on s390x hosts (with kvstore prestart retries):

```bash
test/s390x/integration_wide.sh
```

For explicit two-node cross-node datapath validation (pod IP + service IP matrix):

```bash
MATRIX_NODE_A=<node-a> MATRIX_NODE_B=<node-b> test/s390x/multinode_matrix.sh
```

For explicit cross-node policy enforcement (baseline allow -> deny -> allow):

```bash
MN_POLICY_CLIENT_NODE=<node-a> MN_POLICY_SERVER_NODE=<node-b> test/s390x/multinode_policy_enforcement.sh
```

For cross-node NodePort and host-network-to-service checks:

```bash
NODEPORT_NODE_A=<node-a> NODEPORT_NODE_B=<node-b> test/s390x/nodeport_crossnode.sh
```

## Key Environment Variables

- `KUBECONFIG` (default: `/etc/kubernetes/admin.conf`)
- `KUBECTL_BIN` / `HELM_BIN`
- `CHART_DIR` (default: `./install/kubernetes/cilium`)
- `CILIUM_IMAGE_REPO` / `CILIUM_IMAGE_TAG`
- `OPERATOR_IMAGE_OVERRIDE`
- `ENVOY_IMAGE_REPO` / `ENVOY_IMAGE_TAG`
- `IPAM_MODE` (default: `kubernetes`)
- `ENABLE_POLICY` (optional helm override)
- `REQUIRE_COREDNS` (default: `true`)
- `HOST_TO_POD_PROBE` (default: `true`)
- `HOST_TO_POD_TARGET` (default: `coredns`; options: `coredns`, `cilium-health`)
- `RUN_POLICY_INTEGRATION` (default: `false`, only used by `run_harness.sh`)
- `RUN_BPF_REGRESSION_SUBSET` (default: `false`, only used by `run_harness.sh`)
- `HARNESS_SCRIPT` (default: `test/s390x/run_harness.sh`, used by `launch_logged_run.sh`)
- `RUN_ID` (default: `adhoc`, used by `launch_logged_run.sh`)
- `RUN_COMPONENT` (default: `s390x-harness`, used by `launch_logged_run.sh`)
- `RUN_DAY` / `RUN_TS` (default: current UTC date/timestamp, used by `launch_logged_run.sh`)
- `LOG_DIR` / `LOG_FILE` / `STATUS_FILE` (optional output overrides, used by `launch_logged_run.sh`)
- `KVSTORE_RETRIES` (default: `5`, only used by `integration_wide.sh`)
- `KVSTORE_RETRY_DELAY_SECONDS` (default: `2`, only used by `integration_wide.sh`)
- `INTEGRATION_MAKE_TARGET` (default: `integration-tests`, only used by `integration_wide.sh`)
- `USE_PODMAN_MTU_WORKAROUND` (default: `true`, only used by `integration_wide.sh`)
- `KVSTORE_NETWORK_NAME` (default: `cilium-etcd-net`, only used by `integration_wide.sh`)
- `KVSTORE_NETWORK_MTU` (default: `1500`, only used by `integration_wide.sh`)
- `POLICY_TEST_IMAGE` (default: `registry.k8s.io/e2e-test-images/agnhost:2.53`)
- `POLICY_TEST_NAMESPACE` (default: auto-generated `s390x-policy-<timestamp>`)
- `POLICY_TEST_TIMEOUT_SECONDS` (default: `180`)
- `POLICY_TEST_PORT` (default: `8080`)
- `MATRIX_NAMESPACE` (default: `s390x-crossnode`)
- `MATRIX_IMAGE` (default: `registry.k8s.io/e2e-test-images/agnhost:2.53`)
- `MATRIX_PORT` (default: `8080`)
- `MATRIX_TIMEOUT_SECONDS` (default: `240`)
- `MATRIX_NODE_A` / `MATRIX_NODE_B` (default: first two cluster nodes)
- `MATRIX_RESET_NAMESPACE` (default: `true`)
- `MATRIX_KEEP_NAMESPACE` (default: `true`)
- `MN_POLICY_NAMESPACE` (default: auto-generated `s390x-policy-mn-<timestamp>`)
- `MN_POLICY_IMAGE` (default: `registry.k8s.io/e2e-test-images/agnhost:2.53`)
- `MN_POLICY_PORT` (default: `8080`)
- `MN_POLICY_TIMEOUT_SECONDS` (default: `240`)
- `MN_POLICY_KEEP_NAMESPACE` (default: `false`)
- `MN_POLICY_NODE_A` / `MN_POLICY_NODE_B` (default: first two cluster nodes)
- `MN_POLICY_CLIENT_NODE` / `MN_POLICY_SERVER_NODE` (default: node A / node B)
- `NODEPORT_NAMESPACE` (default: `s390x-nodeport`)
- `NODEPORT_IMAGE` (default: `registry.k8s.io/e2e-test-images/agnhost:2.53`)
- `NODEPORT_PORT` (default: `8080`)
- `NODEPORT_SERVICE_NODEPORT` (default: `32080`)
- `NODEPORT_TIMEOUT_SECONDS` (default: `240`)
- `NODEPORT_NODE_A` / `NODEPORT_NODE_B` (default: first two cluster nodes)
- `NODEPORT_RESET_NAMESPACE` (default: `true`)
- `NODEPORT_KEEP_NAMESPACE` (default: `true`)
- `BPF_STACK_SIZE` (default: `1024`, for `bpf_regression_subset.sh`)
- `BPF_REGRESSION_TESTS` (default: `tc_lxc_policy_drop tc_policy_reject_response_test hairpin_sctp_flow`)
- `SMOKE_LOG_DIR` / `OUT_DIR`
- `TIMEOUT` (default: `15m`)

Note:
- `deploy_cilium_s390x.sh` includes a local-runner fallback for default image refs:
  when the default `cilium-dev`/`operator-dev` tag is missing from CRI cache,
  it auto-selects the first cached tag for that repo. Explicit env overrides still take precedence.

The scripts are intentionally isolated from default CI paths and only execute
when called explicitly.

## Reporting / Evidence

- Reporting flow and sanitation rules: `docs/s390x/reporting-flow.md`
- Daily journal: `docs/s390x/zkd0-build-journal-YYYY-MM-DD.md`
- Daily run index: `docs/s390x/logs/YYYY-MM-DD/RUN-INDEX.md`
