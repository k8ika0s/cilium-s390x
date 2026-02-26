#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"
NAMESPACE="${NAMESPACE:-kube-system}"
TIMEOUT="${TIMEOUT:-600s}"
REQUIRE_COREDNS="${REQUIRE_COREDNS:-true}"
HOST_TO_POD_PROBE="${HOST_TO_POD_PROBE:-true}"
HOST_TO_POD_TARGET="${HOST_TO_POD_TARGET:-coredns}"
HOST_TO_POD_RETRIES="${HOST_TO_POD_RETRIES:-20}"
HOST_TO_POD_RETRY_SLEEP_SECONDS="${HOST_TO_POD_RETRY_SLEEP_SECONDS:-2}"
KUBE_DNS_ENDPOINT_RETRIES="${KUBE_DNS_ENDPOINT_RETRIES:-20}"
KUBE_DNS_ENDPOINT_RETRY_SLEEP_SECONDS="${KUBE_DNS_ENDPOINT_RETRY_SLEEP_SECONDS:-2}"
SMOKE_LOG_DIR="${SMOKE_LOG_DIR:-/tmp/cilium-s390x-smoke-$(date -u +%Y%m%dT%H%M%SZ)}"

export KUBECONFIG
mkdir -p "${SMOKE_LOG_DIR}"

echo "Cluster nodes"
"${KUBECTL_BIN}" get nodes -o wide

echo "Waiting for node readiness"
"${KUBECTL_BIN}" wait --for=condition=Ready node --all --timeout="${TIMEOUT}"

echo "Waiting for Cilium DaemonSets/Deployments"
"${KUBECTL_BIN}" -n "${NAMESPACE}" rollout status ds/cilium --timeout="${TIMEOUT}"
"${KUBECTL_BIN}" -n "${NAMESPACE}" rollout status ds/cilium-envoy --timeout="${TIMEOUT}"
"${KUBECTL_BIN}" -n "${NAMESPACE}" rollout status deploy/cilium-operator --timeout="${TIMEOUT}"

echo "Cilium pod status"
"${KUBECTL_BIN}" -n "${NAMESPACE}" get pods -l k8s-app=cilium -o wide
"${KUBECTL_BIN}" -n "${NAMESPACE}" get pods -l k8s-app=cilium-envoy -o wide
"${KUBECTL_BIN}" -n "${NAMESPACE}" get pods -l io.cilium/app=operator -o wide

latest_running_pod_name() {
  local selector="$1"
  "${KUBECTL_BIN}" -n "${NAMESPACE}" get pods \
    -l "${selector}" \
    --field-selector=status.phase=Running \
    --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{.items[-1:].metadata.name}'
}

latest_running_pod_ip() {
  local selector="$1"
  "${KUBECTL_BIN}" -n "${NAMESPACE}" get pods \
    -l "${selector}" \
    --field-selector=status.phase=Running \
    --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{.items[-1:].status.podIP}'
}

cilium_agent_exec() {
  local agent_pod container_names
  agent_pod="$(latest_running_pod_name "k8s-app=cilium")"
  if [[ -z "${agent_pod}" ]]; then
    echo "unable to find running cilium pod" >&2
    return 1
  fi

  container_names="$("${KUBECTL_BIN}" -n "${NAMESPACE}" get pod "${agent_pod}" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null || true)"
  if [[ " ${container_names} " == *" cilium-agent "* ]]; then
    "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${agent_pod}" -c cilium-agent -- "$@"
  else
    "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${agent_pod}" -- "$@"
  fi
}

check_cluster_health() {
  cilium_agent_exec cilium status --verbose >"${SMOKE_LOG_DIR}/cilium-status-verbose.txt"
  local line reachable total
  line="$(grep -E 'Cluster health:' "${SMOKE_LOG_DIR}/cilium-status-verbose.txt" | head -n 1 || true)"
  if [[ "${line}" =~ Cluster\ health:[[:space:]]+([0-9]+)/([0-9]+)[[:space:]]+reachable ]]; then
    reachable="${BASH_REMATCH[1]}"
    total="${BASH_REMATCH[2]}"
    # Single-node clusters may report 0/0 because there are no remote nodes to probe.
    if [[ "${total}" == "0" ]]; then
      return 0
    fi
    if [[ "${reachable}" == "0" ]]; then
      echo "cluster health has zero reachable endpoints (${reachable}/${total})"
      return 1
    fi
  elif grep -Eq 'Cluster health:[[:space:]]+0/' "${SMOKE_LOG_DIR}/cilium-status-verbose.txt"; then
    echo "cluster health has zero reachable endpoints"
    return 1
  fi
}

check_cilium_endpoints() {
  local endpoint_count
  endpoint_count="$("${KUBECTL_BIN}" -n "${NAMESPACE}" get ciliumendpoints.cilium.io --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  if [[ -z "${endpoint_count}" || "${endpoint_count}" == "0" ]]; then
    echo "no CiliumEndpoint resources found"
    return 1
  fi
}

check_kube_dns_endpoints() {
  local endpoints attempt

  for ((attempt=1; attempt<=KUBE_DNS_ENDPOINT_RETRIES; attempt++)); do
    endpoints="$("${KUBECTL_BIN}" -n "${NAMESPACE}" get endpoints kube-dns -o jsonpath='{.subsets[*].addresses[*].ip}')"
    if [[ -n "${endpoints}" ]]; then
      return 0
    fi
    sleep "${KUBE_DNS_ENDPOINT_RETRY_SLEEP_SECONDS}"
  done

  echo "kube-dns service has no ready endpoints after ${KUBE_DNS_ENDPOINT_RETRIES} attempts"
  return 1
}

check_coredns_rollout() {
  "${KUBECTL_BIN}" -n "${NAMESPACE}" rollout status deploy/coredns --timeout="${TIMEOUT}"
}

check_host_to_pod_health() {
  local attempt coredns_pod_ip health_pod_ip status_out

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required for host-to-pod probe"
    return 1
  fi

  case "${HOST_TO_POD_TARGET}" in
    cilium-health)
      status_out="$(cilium_agent_exec cilium status --verbose)"
      health_pod_ip="$(printf '%s\n' "${status_out}" | sed -n 's/.*Endpoint connectivity to \([0-9.]*\):.*/\1/p' | head -n1)"
      if [[ -z "${health_pod_ip}" ]]; then
        # Fallback for versions that only print health endpoint under IPAM allocations.
        health_pod_ip="$(printf '%s\n' "${status_out}" | sed -n 's/^[[:space:]]*\([0-9.]\+\)[[:space:]]*(health)$/\1/p' | head -n1)"
      fi
      if [[ -z "${health_pod_ip}" ]]; then
        echo "unable to determine cilium-health endpoint IP"
        return 1
      fi

      for ((attempt=1; attempt<=HOST_TO_POD_RETRIES; attempt++)); do
        if curl -fsS --max-time 3 "http://${health_pod_ip}:4240/hello" >/dev/null; then
          return 0
        fi
        sleep "${HOST_TO_POD_RETRY_SLEEP_SECONDS}"
      done

      echo "host-to-pod cilium-health probe failed after ${HOST_TO_POD_RETRIES} attempts"
      return 1
      ;;
    coredns)
      coredns_pod_ip="$(latest_running_pod_ip "k8s-app=kube-dns" 2>/dev/null || true)"
      if [[ -z "${coredns_pod_ip}" ]]; then
        echo "unable to determine CoreDNS pod IP"
        return 1
      fi

      for ((attempt=1; attempt<=HOST_TO_POD_RETRIES; attempt++)); do
        if curl -fsS --max-time 3 "http://${coredns_pod_ip}:8080/health" >/dev/null; then
          return 0
        fi
        sleep "${HOST_TO_POD_RETRY_SLEEP_SECONDS}"
      done

      echo "host-to-pod CoreDNS probe failed after ${HOST_TO_POD_RETRIES} attempts"
      return 1
      ;;
    *)
      echo "unsupported HOST_TO_POD_TARGET=${HOST_TO_POD_TARGET} (expected coredns or cilium-health)"
      return 1
      ;;
  esac
}

run_check() {
  local name="$1"
  shift
  (
    set -euo pipefail
    "$@"
  ) >"${SMOKE_LOG_DIR}/${name}.log" 2>&1 &
  CHECK_PIDS+=("$!")
  CHECK_NAMES+=("${name}")
}

CHECK_PIDS=()
CHECK_NAMES=()
FAILED_CHECKS=()

run_check "cluster-health" check_cluster_health
run_check "cilium-endpoints" check_cilium_endpoints

if [[ "${REQUIRE_COREDNS}" == "true" ]]; then
  run_check "kube-dns-endpoints" check_kube_dns_endpoints
  run_check "coredns-rollout" check_coredns_rollout
fi

if [[ "${HOST_TO_POD_PROBE}" == "true" ]]; then
  run_check "host-to-pod-health" check_host_to_pod_health
fi

for idx in "${!CHECK_PIDS[@]}"; do
  if ! wait "${CHECK_PIDS[${idx}]}"; then
    FAILED_CHECKS+=("${CHECK_NAMES[${idx}]}")
  fi
done

if ((${#FAILED_CHECKS[@]} > 0)); then
  echo "Smoke checks failed: ${FAILED_CHECKS[*]}"
  for check in "${FAILED_CHECKS[@]}"; do
    echo "----- ${check} -----"
    cat "${SMOKE_LOG_DIR}/${check}.log"
  done
  exit 1
fi

AGENT_POD="$(latest_running_pod_name "k8s-app=cilium" 2>/dev/null || true)"
echo "cilium status from ${AGENT_POD:-unknown}"
cat "${SMOKE_LOG_DIR}/cilium-status-verbose.txt"

echo "Smoke checks passed"
