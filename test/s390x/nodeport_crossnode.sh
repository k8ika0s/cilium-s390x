#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"

NODEPORT_NAMESPACE="${NODEPORT_NAMESPACE:-s390x-nodeport}"
NODEPORT_IMAGE="${NODEPORT_IMAGE:-registry.k8s.io/e2e-test-images/agnhost:2.53}"
NODEPORT_PORT="${NODEPORT_PORT:-8080}"
NODEPORT_SERVICE_NODEPORT="${NODEPORT_SERVICE_NODEPORT:-32080}"
NODEPORT_TIMEOUT_SECONDS="${NODEPORT_TIMEOUT_SECONDS:-240}"

NODEPORT_NODE_A="${NODEPORT_NODE_A:-}"
NODEPORT_NODE_B="${NODEPORT_NODE_B:-}"

NODEPORT_RESET_NAMESPACE="${NODEPORT_RESET_NAMESPACE:-true}"
NODEPORT_KEEP_NAMESPACE="${NODEPORT_KEEP_NAMESPACE:-true}"

export KUBECONFIG

log() {
  printf '%s %s\n' "[$(date -u +%Y-%m-%dT%H:%M:%SZ)]" "$*"
}

cleanup() {
  if [[ "${NODEPORT_KEEP_NAMESPACE}" != "true" ]]; then
    "${KUBECTL_BIN}" delete ns "${NODEPORT_NAMESPACE}" --ignore-not-found=true --wait=false >/dev/null 2>&1 || true
  fi
}

ensure_nodes() {
  local nodes
  mapfile -t nodes < <("${KUBECTL_BIN}" get nodes --no-headers -o custom-columns=NAME:.metadata.name)
  if (( ${#nodes[@]} < 2 )); then
    echo "need at least 2 cluster nodes; found ${#nodes[@]}" >&2
    exit 1
  fi

  if [[ -z "${NODEPORT_NODE_A}" ]]; then
    NODEPORT_NODE_A="${nodes[0]}"
  fi
  if [[ -z "${NODEPORT_NODE_B}" ]]; then
    NODEPORT_NODE_B="${nodes[1]}"
  fi

  if [[ "${NODEPORT_NODE_A}" == "${NODEPORT_NODE_B}" ]]; then
    echo "NODEPORT_NODE_A and NODEPORT_NODE_B must be different" >&2
    exit 1
  fi
}

wait_namespace_deleted() {
  local deadline now
  deadline=$(( $(date +%s) + NODEPORT_TIMEOUT_SECONDS ))
  while true; do
    if ! "${KUBECTL_BIN}" get ns "${NODEPORT_NAMESPACE}" >/dev/null 2>&1; then
      return 0
    fi
    now=$(date +%s)
    if (( now >= deadline )); then
      echo "timed out waiting for namespace ${NODEPORT_NAMESPACE} deletion" >&2
      return 1
    fi
    sleep 2
  done
}

wait_connect_from_pod() {
  local pod="$1"
  local target="$2"
  local label="$3"
  local deadline now
  deadline=$(( $(date +%s) + NODEPORT_TIMEOUT_SECONDS ))
  while true; do
    if "${KUBECTL_BIN}" -n "${NODEPORT_NAMESPACE}" exec "${pod}" -- /agnhost connect --timeout=3s "${target}" >/dev/null 2>&1; then
      echo "[PASS] ${label}"
      return 0
    fi
    now=$(date +%s)
    if (( now >= deadline )); then
      echo "[FAIL] ${label} (timeout target=${target})" >&2
      "${KUBECTL_BIN}" -n "${NODEPORT_NAMESPACE}" exec "${pod}" -- /agnhost connect --timeout=3s "${target}" || true
      return 1
    fi
    sleep 2
  done
}

trap cleanup EXIT

ensure_nodes
log "node_a=${NODEPORT_NODE_A} node_b=${NODEPORT_NODE_B} namespace=${NODEPORT_NAMESPACE}"

if [[ "${NODEPORT_RESET_NAMESPACE}" == "true" ]]; then
  "${KUBECTL_BIN}" delete ns "${NODEPORT_NAMESPACE}" --ignore-not-found=true --wait=false >/dev/null 2>&1 || true
  wait_namespace_deleted
fi

if ! "${KUBECTL_BIN}" get ns "${NODEPORT_NAMESPACE}" >/dev/null 2>&1; then
  "${KUBECTL_BIN}" create ns "${NODEPORT_NAMESPACE}" >/dev/null
fi

cat <<EOF | "${KUBECTL_BIN}" -n "${NODEPORT_NAMESPACE}" apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: server-a
  labels:
    app: np-server
spec:
  nodeName: ${NODEPORT_NODE_A}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: server
    image: ${NODEPORT_IMAGE}
    command: ["/agnhost","netexec","--http-port=${NODEPORT_PORT}"]
---
apiVersion: v1
kind: Pod
metadata:
  name: server-b
  labels:
    app: np-server
spec:
  nodeName: ${NODEPORT_NODE_B}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: server
    image: ${NODEPORT_IMAGE}
    command: ["/agnhost","netexec","--http-port=${NODEPORT_PORT}"]
---
apiVersion: v1
kind: Pod
metadata:
  name: client-a
spec:
  nodeName: ${NODEPORT_NODE_A}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: client
    image: ${NODEPORT_IMAGE}
    command: ["/agnhost","pause"]
---
apiVersion: v1
kind: Pod
metadata:
  name: client-b
spec:
  nodeName: ${NODEPORT_NODE_B}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: client
    image: ${NODEPORT_IMAGE}
    command: ["/agnhost","pause"]
---
apiVersion: v1
kind: Pod
metadata:
  name: hostprobe-a
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
  nodeName: ${NODEPORT_NODE_A}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: hostprobe
    image: ${NODEPORT_IMAGE}
    command: ["/agnhost","pause"]
---
apiVersion: v1
kind: Pod
metadata:
  name: hostprobe-b
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
  nodeName: ${NODEPORT_NODE_B}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: hostprobe
    image: ${NODEPORT_IMAGE}
    command: ["/agnhost","pause"]
---
apiVersion: v1
kind: Service
metadata:
  name: np-server
spec:
  type: NodePort
  selector:
    app: np-server
  ports:
  - protocol: TCP
    port: ${NODEPORT_PORT}
    targetPort: ${NODEPORT_PORT}
    nodePort: ${NODEPORT_SERVICE_NODEPORT}
EOF

"${KUBECTL_BIN}" -n "${NODEPORT_NAMESPACE}" wait --for=condition=Ready \
  pod/server-a pod/server-b pod/client-a pod/client-b pod/hostprobe-a pod/hostprobe-b \
  --timeout="${NODEPORT_TIMEOUT_SECONDS}s" >/dev/null

node_a_ip="$("${KUBECTL_BIN}" get node "${NODEPORT_NODE_A}" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')"
node_b_ip="$("${KUBECTL_BIN}" get node "${NODEPORT_NODE_B}" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')"
cluster_ip="$("${KUBECTL_BIN}" -n "${NODEPORT_NAMESPACE}" get svc np-server -o jsonpath='{.spec.clusterIP}')"
endpoints="$("${KUBECTL_BIN}" -n "${NODEPORT_NAMESPACE}" get endpoints np-server -o jsonpath='{.subsets[*].addresses[*].ip}')"

log "node_a_ip=${node_a_ip} node_b_ip=${node_b_ip} nodeport=${NODEPORT_SERVICE_NODEPORT} cluster_ip=${cluster_ip}"
echo "[endpoints] ${endpoints}"

failures=0
wait_connect_from_pod client-a "${node_b_ip}:${NODEPORT_SERVICE_NODEPORT}" "pod-a-to-node-b-nodeport" || failures=$((failures + 1))
wait_connect_from_pod client-b "${node_a_ip}:${NODEPORT_SERVICE_NODEPORT}" "pod-b-to-node-a-nodeport" || failures=$((failures + 1))
wait_connect_from_pod hostprobe-a "${node_b_ip}:${NODEPORT_SERVICE_NODEPORT}" "hostnet-a-to-node-b-nodeport" || failures=$((failures + 1))
wait_connect_from_pod hostprobe-b "${node_a_ip}:${NODEPORT_SERVICE_NODEPORT}" "hostnet-b-to-node-a-nodeport" || failures=$((failures + 1))
wait_connect_from_pod client-a "${cluster_ip}:${NODEPORT_PORT}" "pod-a-to-clusterip" || failures=$((failures + 1))
wait_connect_from_pod client-b "${cluster_ip}:${NODEPORT_PORT}" "pod-b-to-clusterip" || failures=$((failures + 1))

if (( failures > 0 )); then
  echo "nodeport cross-node test failed (${failures} check(s) failed)" >&2
  exit 1
fi

echo "nodeport cross-node test passed"
