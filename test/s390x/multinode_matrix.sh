#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"

MATRIX_NAMESPACE="${MATRIX_NAMESPACE:-s390x-crossnode}"
MATRIX_IMAGE="${MATRIX_IMAGE:-registry.k8s.io/e2e-test-images/agnhost:2.53}"
MATRIX_PORT="${MATRIX_PORT:-8080}"
MATRIX_TIMEOUT_SECONDS="${MATRIX_TIMEOUT_SECONDS:-240}"

MATRIX_NODE_A="${MATRIX_NODE_A:-}"
MATRIX_NODE_B="${MATRIX_NODE_B:-}"

MATRIX_RESET_NAMESPACE="${MATRIX_RESET_NAMESPACE:-true}"
MATRIX_KEEP_NAMESPACE="${MATRIX_KEEP_NAMESPACE:-true}"

export KUBECONFIG

log() {
  printf '%s %s\n' "[$(date -u +%Y-%m-%dT%H:%M:%SZ)]" "$*"
}

ensure_two_nodes() {
  local nodes
  mapfile -t nodes < <("${KUBECTL_BIN}" get nodes --no-headers -o custom-columns=NAME:.metadata.name)
  if (( ${#nodes[@]} < 2 )); then
    echo "need at least 2 cluster nodes; found ${#nodes[@]}" >&2
    exit 1
  fi

  if [[ -z "${MATRIX_NODE_A}" ]]; then
    MATRIX_NODE_A="${nodes[0]}"
  fi
  if [[ -z "${MATRIX_NODE_B}" ]]; then
    MATRIX_NODE_B="${nodes[1]}"
  fi

  if [[ "${MATRIX_NODE_A}" == "${MATRIX_NODE_B}" ]]; then
    echo "MATRIX_NODE_A and MATRIX_NODE_B must be different" >&2
    exit 1
  fi
}

wait_namespace_gone() {
  local deadline now
  deadline=$(( $(date +%s) + MATRIX_TIMEOUT_SECONDS ))
  while true; do
    if ! "${KUBECTL_BIN}" get ns "${MATRIX_NAMESPACE}" >/dev/null 2>&1; then
      return 0
    fi
    now=$(date +%s)
    if (( now >= deadline )); then
      echo "timed out waiting for namespace ${MATRIX_NAMESPACE} deletion" >&2
      return 1
    fi
    sleep 2
  done
}

cleanup() {
  if [[ "${MATRIX_KEEP_NAMESPACE}" != "true" ]]; then
    log "Deleting namespace ${MATRIX_NAMESPACE}"
    "${KUBECTL_BIN}" delete ns "${MATRIX_NAMESPACE}" --ignore-not-found=true --wait=false >/dev/null 2>&1 || true
  fi
}

run_connectivity_check() {
  local name="$1"
  local client="$2"
  local target="$3"
  log "check=${name} client=${client} target=${target}:${MATRIX_PORT}"
  if "${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" exec "${client}" -- /agnhost connect --timeout=5s "${target}:${MATRIX_PORT}" >/dev/null 2>&1; then
    echo "[PASS] ${name}"
    return 0
  fi

  echo "[FAIL] ${name}"
  "${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" exec "${client}" -- /agnhost connect --timeout=5s "${target}:${MATRIX_PORT}" || true
  return 1
}

trap cleanup EXIT

ensure_two_nodes
log "node_a=${MATRIX_NODE_A} node_b=${MATRIX_NODE_B} namespace=${MATRIX_NAMESPACE}"

if [[ "${MATRIX_RESET_NAMESPACE}" == "true" ]]; then
  log "Resetting namespace ${MATRIX_NAMESPACE}"
  "${KUBECTL_BIN}" delete ns "${MATRIX_NAMESPACE}" --ignore-not-found=true --wait=false >/dev/null 2>&1 || true
  wait_namespace_gone
fi

if ! "${KUBECTL_BIN}" get ns "${MATRIX_NAMESPACE}" >/dev/null 2>&1; then
  "${KUBECTL_BIN}" create ns "${MATRIX_NAMESPACE}" >/dev/null
fi

log "Applying matrix pods/services"
cat <<EOF | "${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: server-a
  labels:
    app: server-a
spec:
  nodeName: ${MATRIX_NODE_A}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: server
    image: ${MATRIX_IMAGE}
    command: ["/agnhost","netexec","--http-port=${MATRIX_PORT}"]
---
apiVersion: v1
kind: Pod
metadata:
  name: client-a
  labels:
    app: client-a
spec:
  nodeName: ${MATRIX_NODE_A}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: client
    image: ${MATRIX_IMAGE}
    command: ["/agnhost","pause"]
---
apiVersion: v1
kind: Pod
metadata:
  name: server-b
  labels:
    app: server-b
spec:
  nodeName: ${MATRIX_NODE_B}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: server
    image: ${MATRIX_IMAGE}
    command: ["/agnhost","netexec","--http-port=${MATRIX_PORT}"]
---
apiVersion: v1
kind: Pod
metadata:
  name: client-b
  labels:
    app: client-b
spec:
  nodeName: ${MATRIX_NODE_B}
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  containers:
  - name: client
    image: ${MATRIX_IMAGE}
    command: ["/agnhost","pause"]
---
apiVersion: v1
kind: Service
metadata:
  name: svc-server-a
spec:
  selector:
    app: server-a
  ports:
  - protocol: TCP
    port: ${MATRIX_PORT}
    targetPort: ${MATRIX_PORT}
---
apiVersion: v1
kind: Service
metadata:
  name: svc-server-b
spec:
  selector:
    app: server-b
  ports:
  - protocol: TCP
    port: ${MATRIX_PORT}
    targetPort: ${MATRIX_PORT}
EOF

log "Waiting for matrix pods"
"${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" wait \
  --for=condition=Ready \
  pod/server-a pod/client-a pod/server-b pod/client-b \
  --timeout="${MATRIX_TIMEOUT_SECONDS}s" >/dev/null

SERVER_A_IP="$("${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" get pod server-a -o jsonpath='{.status.podIP}')"
SERVER_B_IP="$("${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" get pod server-b -o jsonpath='{.status.podIP}')"
SVC_A_IP="$("${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" get svc svc-server-a -o jsonpath='{.spec.clusterIP}')"
SVC_B_IP="$("${KUBECTL_BIN}" -n "${MATRIX_NAMESPACE}" get svc svc-server-b -o jsonpath='{.spec.clusterIP}')"

log "server_a=${SERVER_A_IP} server_b=${SERVER_B_IP} svc_a=${SVC_A_IP} svc_b=${SVC_B_IP}"

failures=0
run_connectivity_check "same-node-a" "client-a" "${SERVER_A_IP}" || failures=$((failures + 1))
run_connectivity_check "same-node-b" "client-b" "${SERVER_B_IP}" || failures=$((failures + 1))
run_connectivity_check "cross-a-to-b" "client-a" "${SERVER_B_IP}" || failures=$((failures + 1))
run_connectivity_check "cross-b-to-a" "client-b" "${SERVER_A_IP}" || failures=$((failures + 1))
run_connectivity_check "service-a-to-b" "client-a" "${SVC_B_IP}" || failures=$((failures + 1))
run_connectivity_check "service-b-to-a" "client-b" "${SVC_A_IP}" || failures=$((failures + 1))

log "cilium-health snapshot"
for pod in $("${KUBECTL_BIN}" -n kube-system get pods -l k8s-app=cilium -o name); do
  echo "== ${pod}"
  "${KUBECTL_BIN}" -n kube-system exec "${pod}" -- cilium-health status || failures=$((failures + 1))
done

if (( failures > 0 )); then
  echo "multinode matrix failed (${failures} check(s) failed)" >&2
  exit 1
fi

echo "multinode matrix passed"
