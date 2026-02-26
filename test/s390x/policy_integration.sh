#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"
POLICY_TEST_IMAGE="${POLICY_TEST_IMAGE:-registry.k8s.io/e2e-test-images/agnhost:2.53}"
POLICY_TEST_NAMESPACE="${POLICY_TEST_NAMESPACE:-s390x-policy-$(date -u +%Y%m%d%H%M%S)}"
POLICY_TEST_TIMEOUT_SECONDS="${POLICY_TEST_TIMEOUT_SECONDS:-180}"
POLICY_TEST_PORT="${POLICY_TEST_PORT:-8080}"

export KUBECONFIG

cleanup() {
  "${KUBECTL_BIN}" delete ns "${POLICY_TEST_NAMESPACE}" --ignore-not-found=true --wait=false >/dev/null 2>&1 || true
}

wait_for_client_identity_convergence() {
  local deadline now state labels
  deadline=$(( $(date +%s) + POLICY_TEST_TIMEOUT_SECONDS ))

  while true; do
    now=$(date +%s)
    if (( now >= deadline )); then
      echo "timed out waiting for client CiliumEndpoint identity convergence" >&2
      return 1
    fi

    state="$("${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" get ciliumendpoints.cilium.io client -o jsonpath='{.status.state}' 2>/dev/null || true)"
    labels="$("${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" get ciliumendpoints.cilium.io client -o jsonpath='{.status.identity.labels}' 2>/dev/null || true)"

    if [[ "${state}" == "ready" ]] && grep -q "k8s:access=granted" <<<"${labels}"; then
      return 0
    fi

    sleep 2
  done
}

wait_for_connectivity() {
  local server_addr="$1"
  local deadline now
  deadline=$(( $(date +%s) + POLICY_TEST_TIMEOUT_SECONDS ))

  while true; do
    now=$(date +%s)
    if (( now >= deadline )); then
      echo "timed out waiting for connectivity to ${server_addr}" >&2
      return 1
    fi

    if "${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" exec client -- /agnhost connect --timeout=3s "${server_addr}" >/dev/null 2>&1; then
      return 0
    fi

    sleep 2
  done
}

trap cleanup EXIT

echo "Creating namespace ${POLICY_TEST_NAMESPACE}"
"${KUBECTL_BIN}" create ns "${POLICY_TEST_NAMESPACE}" >/dev/null

cat <<EOF | "${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: server
  labels:
    app: server
spec:
  tolerations:
  - key: node.kubernetes.io/disk-pressure
    operator: Exists
    effect: NoSchedule
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: server
    image: ${POLICY_TEST_IMAGE}
    command: ["/agnhost","netexec","--http-port=${POLICY_TEST_PORT}"]
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  labels:
    app: client
spec:
  tolerations:
  - key: node.kubernetes.io/disk-pressure
    operator: Exists
    effect: NoSchedule
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: client
    image: ${POLICY_TEST_IMAGE}
    command: ["/agnhost","pause"]
EOF

"${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" wait --for=condition=Ready pod/server pod/client --timeout="${POLICY_TEST_TIMEOUT_SECONDS}s"
SERVER_IP="$("${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" get pod server -o jsonpath='{.status.podIP}')"
SERVER_ADDR="${SERVER_IP}:${POLICY_TEST_PORT}"

echo "Baseline connectivity to ${SERVER_ADDR} (expected: allow)"
wait_for_connectivity "${SERVER_ADDR}"

cat <<EOF | "${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" apply -f - >/dev/null
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-server-from-granted
spec:
  endpointSelector:
    matchLabels:
      k8s:app: server
      k8s:io.kubernetes.pod.namespace: ${POLICY_TEST_NAMESPACE}
  ingress:
  - fromEndpoints:
    - matchLabels:
        k8s:access: granted
        k8s:io.kubernetes.pod.namespace: ${POLICY_TEST_NAMESPACE}
    toPorts:
    - ports:
      - port: "${POLICY_TEST_PORT}"
        protocol: TCP
EOF

sleep 5

echo "Connectivity without access label (expected: deny)"
if "${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" exec client -- /agnhost connect --timeout=3s "${SERVER_ADDR}" >/dev/null 2>&1; then
  echo "unexpected success without access label" >&2
  exit 1
fi

"${KUBECTL_BIN}" -n "${POLICY_TEST_NAMESPACE}" label pod client access=granted --overwrite >/dev/null
wait_for_client_identity_convergence

echo "Connectivity with access label after CEP convergence (expected: allow)"
wait_for_connectivity "${SERVER_ADDR}"

echo "Policy integration test passed"
