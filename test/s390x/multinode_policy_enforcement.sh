#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"

MN_POLICY_NAMESPACE="${MN_POLICY_NAMESPACE:-s390x-policy-mn-$(date -u +%Y%m%d%H%M%S)}"
MN_POLICY_IMAGE="${MN_POLICY_IMAGE:-registry.k8s.io/e2e-test-images/agnhost:2.53}"
MN_POLICY_PORT="${MN_POLICY_PORT:-8080}"
MN_POLICY_TIMEOUT_SECONDS="${MN_POLICY_TIMEOUT_SECONDS:-240}"
MN_POLICY_KEEP_NAMESPACE="${MN_POLICY_KEEP_NAMESPACE:-false}"

MN_POLICY_NODE_A="${MN_POLICY_NODE_A:-}"
MN_POLICY_NODE_B="${MN_POLICY_NODE_B:-}"
MN_POLICY_CLIENT_NODE="${MN_POLICY_CLIENT_NODE:-}"
MN_POLICY_SERVER_NODE="${MN_POLICY_SERVER_NODE:-}"

export KUBECONFIG

log() {
  printf '%s %s\n' "[$(date -u +%Y-%m-%dT%H:%M:%SZ)]" "$*"
}

cleanup() {
  if [[ "${MN_POLICY_KEEP_NAMESPACE}" != "true" ]]; then
    "${KUBECTL_BIN}" delete ns "${MN_POLICY_NAMESPACE}" --ignore-not-found=true --wait=false >/dev/null 2>&1 || true
  fi
}

ensure_nodes() {
  local nodes
  mapfile -t nodes < <("${KUBECTL_BIN}" get nodes --no-headers -o custom-columns=NAME:.metadata.name)
  if (( ${#nodes[@]} < 2 )); then
    echo "need at least 2 cluster nodes; found ${#nodes[@]}" >&2
    exit 1
  fi

  if [[ -z "${MN_POLICY_NODE_A}" ]]; then
    MN_POLICY_NODE_A="${nodes[0]}"
  fi
  if [[ -z "${MN_POLICY_NODE_B}" ]]; then
    MN_POLICY_NODE_B="${nodes[1]}"
  fi
  if [[ -z "${MN_POLICY_CLIENT_NODE}" ]]; then
    MN_POLICY_CLIENT_NODE="${MN_POLICY_NODE_A}"
  fi
  if [[ -z "${MN_POLICY_SERVER_NODE}" ]]; then
    MN_POLICY_SERVER_NODE="${MN_POLICY_NODE_B}"
  fi

  if [[ "${MN_POLICY_CLIENT_NODE}" == "${MN_POLICY_SERVER_NODE}" ]]; then
    echo "client and server nodes must differ for cross-node policy enforcement" >&2
    exit 1
  fi
}

wait_for_connectivity() {
  local target="$1"
  local deadline now
  deadline=$(( $(date +%s) + MN_POLICY_TIMEOUT_SECONDS ))
  while true; do
    if "${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" exec client -- /agnhost connect --timeout=3s "${target}" >/dev/null 2>&1; then
      return 0
    fi
    now=$(date +%s)
    if (( now >= deadline )); then
      echo "timed out waiting for connectivity to ${target}" >&2
      return 1
    fi
    sleep 2
  done
}

wait_for_client_identity_convergence() {
  local deadline now state labels
  deadline=$(( $(date +%s) + MN_POLICY_TIMEOUT_SECONDS ))
  while true; do
    state="$("${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" get ciliumendpoints.cilium.io client -o jsonpath='{.status.state}' 2>/dev/null || true)"
    labels="$("${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" get ciliumendpoints.cilium.io client -o jsonpath='{.status.identity.labels}' 2>/dev/null || true)"
    if [[ "${state}" == "ready" ]] && grep -q "k8s:access=granted" <<<"${labels}"; then
      return 0
    fi
    now=$(date +%s)
    if (( now >= deadline )); then
      echo "timed out waiting for client CEP label convergence" >&2
      return 1
    fi
    sleep 2
  done
}

trap cleanup EXIT

ensure_nodes
log "namespace=${MN_POLICY_NAMESPACE} client_node=${MN_POLICY_CLIENT_NODE} server_node=${MN_POLICY_SERVER_NODE}"

"${KUBECTL_BIN}" create ns "${MN_POLICY_NAMESPACE}" >/dev/null

cat <<EOF | "${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: server
  labels:
    app: server
spec:
  nodeName: ${MN_POLICY_SERVER_NODE}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: server
    image: ${MN_POLICY_IMAGE}
    command: ["/agnhost","netexec","--http-port=${MN_POLICY_PORT}"]
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  labels:
    app: client
spec:
  nodeName: ${MN_POLICY_CLIENT_NODE}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: client
    image: ${MN_POLICY_IMAGE}
    command: ["/agnhost","pause"]
EOF

"${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" wait --for=condition=Ready pod/server pod/client --timeout="${MN_POLICY_TIMEOUT_SECONDS}s" >/dev/null

server_ip="$("${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" get pod server -o jsonpath='{.status.podIP}')"
server_node="$("${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" get pod server -o jsonpath='{.spec.nodeName}')"
client_node="$("${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" get pod client -o jsonpath='{.spec.nodeName}')"
target="${server_ip}:${MN_POLICY_PORT}"

if [[ "${server_node}" == "${client_node}" ]]; then
  echo "pods landed on same node (${server_node}); expected cross-node placement" >&2
  exit 1
fi

log "baseline allow expected target=${target}"
wait_for_connectivity "${target}"
echo "[PASS] baseline-allow"

cat <<EOF | "${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" apply -f - >/dev/null
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-server-from-granted
spec:
  endpointSelector:
    matchLabels:
      k8s:app: server
      k8s:io.kubernetes.pod.namespace: ${MN_POLICY_NAMESPACE}
  ingress:
  - fromEndpoints:
    - matchLabels:
        k8s:access: granted
        k8s:io.kubernetes.pod.namespace: ${MN_POLICY_NAMESPACE}
    toPorts:
    - ports:
      - port: "${MN_POLICY_PORT}"
        protocol: TCP
EOF

sleep 5
log "deny expected (client has no access label)"
if "${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" exec client -- /agnhost connect --timeout=3s "${target}" >/dev/null 2>&1; then
  echo "[FAIL] policy-deny"
  exit 1
fi
echo "[PASS] policy-deny"

"${KUBECTL_BIN}" -n "${MN_POLICY_NAMESPACE}" label pod client access=granted --overwrite >/dev/null
wait_for_client_identity_convergence
log "allow expected after CEP convergence"
wait_for_connectivity "${target}"
echo "[PASS] policy-allow-after-label"

echo "multinode policy enforcement passed"
