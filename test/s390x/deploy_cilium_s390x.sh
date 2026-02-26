#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
HELM_BIN="${HELM_BIN:-helm}"

if ! command -v "${KUBECTL_BIN}" >/dev/null 2>&1; then
  echo "${KUBECTL_BIN} is required" >&2
  exit 1
fi
if ! command -v "${HELM_BIN}" >/dev/null 2>&1; then
  echo "${HELM_BIN} is required" >&2
  exit 1
fi

KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"
CHART_DIR="${CHART_DIR:-./install/kubernetes/cilium}"
RELEASE="${RELEASE:-cilium}"
NAMESPACE="${NAMESPACE:-kube-system}"
TIMEOUT="${TIMEOUT:-15m}"

CILIUM_IMAGE_REPO="${CILIUM_IMAGE_REPO:-docker.io/cilium/cilium-dev}"
DEFAULT_CILIUM_IMAGE_TAG="1233512912-nogit-wip"
CILIUM_IMAGE_TAG="${CILIUM_IMAGE_TAG:-${DEFAULT_CILIUM_IMAGE_TAG}}"
DEFAULT_OPERATOR_IMAGE_OVERRIDE="docker.io/cilium/operator-dev:1233512912-nogit-wip"
OPERATOR_IMAGE_OVERRIDE="${OPERATOR_IMAGE_OVERRIDE:-${DEFAULT_OPERATOR_IMAGE_OVERRIDE}}"
ENVOY_IMAGE_REPO="${ENVOY_IMAGE_REPO:-quay.io/cilium/cilium-envoy-dev}"
ENVOY_IMAGE_TAG="${ENVOY_IMAGE_TAG:-k8ika0s-s390x-proxy-remediate-s390x}"
IPAM_MODE="${IPAM_MODE:-kubernetes}"
ENABLE_POLICY="${ENABLE_POLICY:-}"

export KUBECONFIG

cri_has_image_ref() {
  local image_ref="$1"
  command -v crictl >/dev/null 2>&1 || return 1
  crictl images 2>/dev/null | awk 'NR > 1 {print $1 ":" $2}' | grep -Fxq "${image_ref}"
}

cri_first_cached_tag() {
  local repo="$1"
  command -v crictl >/dev/null 2>&1 || return 1
  crictl images 2>/dev/null | awk -v repo="${repo}" 'NR > 1 && $1 == repo {print $2; exit}'
}

if [[ "${CILIUM_IMAGE_TAG}" == "${DEFAULT_CILIUM_IMAGE_TAG}" ]]; then
  default_ref="${CILIUM_IMAGE_REPO}:${DEFAULT_CILIUM_IMAGE_TAG}"
  if ! cri_has_image_ref "${default_ref}"; then
    fallback_tag="$(cri_first_cached_tag "${CILIUM_IMAGE_REPO}" || true)"
    if [[ -n "${fallback_tag}" ]]; then
      echo "Default image ${default_ref} not cached; using ${CILIUM_IMAGE_REPO}:${fallback_tag}"
      CILIUM_IMAGE_TAG="${fallback_tag}"
    fi
  fi
fi

if [[ "${OPERATOR_IMAGE_OVERRIDE}" == "${DEFAULT_OPERATOR_IMAGE_OVERRIDE}" ]]; then
  if ! cri_has_image_ref "${DEFAULT_OPERATOR_IMAGE_OVERRIDE}"; then
    operator_repo="${DEFAULT_OPERATOR_IMAGE_OVERRIDE%:*}"
    operator_fallback_tag="$(cri_first_cached_tag "${operator_repo}" || true)"
    if [[ -n "${operator_fallback_tag}" ]]; then
      OPERATOR_IMAGE_OVERRIDE="${operator_repo}:${operator_fallback_tag}"
      echo "Default operator image not cached; using ${OPERATOR_IMAGE_OVERRIDE}"
    fi
  fi
fi

echo "Deploying ${RELEASE} into ${NAMESPACE} from ${CHART_DIR}"

HELM_ARGS=(
  upgrade
  --install
  "${RELEASE}"
  "${CHART_DIR}"
  --namespace "${NAMESPACE}"
  --set "image.repository=${CILIUM_IMAGE_REPO}"
  --set "image.tag=${CILIUM_IMAGE_TAG}"
  --set image.useDigest=false
  --set image.pullPolicy=IfNotPresent
  --set "operator.image.override=${OPERATOR_IMAGE_OVERRIDE}"
  --set operator.image.useDigest=false
  --set operator.image.pullPolicy=IfNotPresent
  --set operator.replicas=1
  --set "envoy.image.repository=${ENVOY_IMAGE_REPO}"
  --set "envoy.image.tag=${ENVOY_IMAGE_TAG}"
  --set envoy.image.useDigest=false
  --set envoy.image.pullPolicy=IfNotPresent
  --set "ipam.mode=${IPAM_MODE}"
  --set preflight.enabled=false
  --set hubble.enabled=false
  --wait
  --timeout "${TIMEOUT}"
)

if [[ -n "${ENABLE_POLICY}" ]]; then
  HELM_ARGS+=(--set "enable-policy=${ENABLE_POLICY}")
fi

"${HELM_BIN}" "${HELM_ARGS[@]}"

echo "Waiting for Cilium workloads"
"${KUBECTL_BIN}" -n "${NAMESPACE}" rollout status ds/cilium --timeout="${TIMEOUT}"
"${KUBECTL_BIN}" -n "${NAMESPACE}" rollout status ds/cilium-envoy --timeout="${TIMEOUT}"
"${KUBECTL_BIN}" -n "${NAMESPACE}" rollout status deploy/cilium-operator --timeout="${TIMEOUT}"

echo "Deployment completed"
