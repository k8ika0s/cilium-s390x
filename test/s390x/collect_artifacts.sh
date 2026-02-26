#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"
NAMESPACE="${NAMESPACE:-kube-system}"
OUT_DIR="${OUT_DIR:-/tmp/cilium-s390x-artifacts-$(date -u +%Y%m%dT%H%M%SZ)}"

export KUBECONFIG

mkdir -p "${OUT_DIR}"

run_capture_bg() {
  local outfile="$1"
  shift
  (
    set +e
    "$@" >"${OUT_DIR}/${outfile}" 2>&1
  ) &
  CAPTURE_PIDS+=("$!")
}

run_capture_eval_bg() {
  local outfile="$1"
  local cmd="$2"
  (
    set +e
    eval "${cmd}" >"${OUT_DIR}/${outfile}" 2>&1
  ) &
  CAPTURE_PIDS+=("$!")
}

CAPTURE_PIDS=()

run_capture_bg "kubectl-version.txt" "${KUBECTL_BIN}" version
run_capture_bg "nodes.txt" "${KUBECTL_BIN}" get nodes -o wide
run_capture_bg "pods-all.txt" "${KUBECTL_BIN}" get pods -A -o wide
run_capture_bg "daemonsets-all.txt" "${KUBECTL_BIN}" get ds -A -o wide
run_capture_bg "deployments-all.txt" "${KUBECTL_BIN}" get deploy -A -o wide
run_capture_bg "services-all.txt" "${KUBECTL_BIN}" get svc -A -o wide
run_capture_bg "events-all.txt" "${KUBECTL_BIN}" get events -A --sort-by=.lastTimestamp
run_capture_bg "ciliumendpoints.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" get ciliumendpoints.cilium.io -o wide
run_capture_bg "describe-cilium-ds.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" describe ds cilium
run_capture_bg "describe-cilium-envoy-ds.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" describe ds cilium-envoy
run_capture_bg "describe-cilium-operator-deploy.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" describe deploy cilium-operator
run_capture_bg "describe-coredns-deploy.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" describe deploy coredns
run_capture_bg "kube-dns-endpoints.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" get endpoints kube-dns -o wide

AGENT_POD="$("${KUBECTL_BIN}" -n "${NAMESPACE}" get pods \
  -l k8s-app=cilium \
  --field-selector=status.phase=Running \
  --sort-by=.metadata.creationTimestamp \
  -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || true)"
if [[ -n "${AGENT_POD}" ]]; then
  AGENT_CONTAINERS="$("${KUBECTL_BIN}" -n "${NAMESPACE}" get pod "${AGENT_POD}" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null || true)"
  if [[ " ${AGENT_CONTAINERS} " == *" cilium-agent "* ]]; then
    run_capture_bg "cilium-status-verbose.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -c cilium-agent -- cilium status --verbose
    run_capture_bg "cilium-endpoint-list.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -c cilium-agent -- cilium-dbg endpoint list
    run_capture_bg "cilium-bpf-ipcache-list.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -c cilium-agent -- cilium-dbg bpf ipcache list
    run_capture_bg "cilium-bpf-ct-global.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -c cilium-agent -- cilium-dbg bpf ct list global
  else
    run_capture_bg "cilium-status-verbose.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -- cilium status --verbose
    run_capture_bg "cilium-endpoint-list.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -- cilium-dbg endpoint list
    run_capture_bg "cilium-bpf-ipcache-list.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -- cilium-dbg bpf ipcache list
    run_capture_bg "cilium-bpf-ct-global.txt" "${KUBECTL_BIN}" -n "${NAMESPACE}" exec "${AGENT_POD}" -- cilium-dbg bpf ct list global
  fi
fi

for pod in $("${KUBECTL_BIN}" -n "${NAMESPACE}" get pods -l k8s-app=cilium -o name 2>/dev/null); do
  name="${pod#pod/}"
  run_capture_bg "${name}-cilium-agent.log" "${KUBECTL_BIN}" -n "${NAMESPACE}" logs "${name}" -c cilium-agent
  run_capture_bg "${name}-clean-cilium-state.log" "${KUBECTL_BIN}" -n "${NAMESPACE}" logs "${name}" -c clean-cilium-state
done

for pod in $("${KUBECTL_BIN}" -n "${NAMESPACE}" get pods -l k8s-app=cilium-envoy -o name 2>/dev/null); do
  name="${pod#pod/}"
  run_capture_bg "${name}-cilium-envoy.log" "${KUBECTL_BIN}" -n "${NAMESPACE}" logs "${name}" -c cilium-envoy
done

for pod in $("${KUBECTL_BIN}" -n "${NAMESPACE}" get pods -l io.cilium/app=operator -o name 2>/dev/null); do
  name="${pod#pod/}"
  run_capture_bg "${name}-operator.log" "${KUBECTL_BIN}" -n "${NAMESPACE}" logs "${name}" -c cilium-operator
done

run_capture_eval_bg "host-ip-route.txt" "ip route"
run_capture_eval_bg "host-ip-rule.txt" "ip rule show"
run_capture_eval_bg "host-sysctl-net.txt" "sysctl net.ipv4.ip_forward net.ipv4.conf.all.forwarding net.ipv4.conf.all.rp_filter net.ipv4.conf.default.rp_filter"

if command -v ethtool >/dev/null 2>&1; then
  run_capture_eval_bg "host-ethtool-cilium-veth.txt" "for dev in cilium_host cilium_net \$(ip -o link show | awk -F': ' '/lxc/{print \$2}' | sed 's/@.*//'); do echo \"=== \$dev ===\"; ethtool -k \"\$dev\" || true; done"
fi

for pid in "${CAPTURE_PIDS[@]}"; do
  wait "${pid}" || true
done

echo "Artifacts collected in ${OUT_DIR}"
