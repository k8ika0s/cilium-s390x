#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

MAKE_BIN="${MAKE_BIN:-make}"
KVSTORE_RETRIES="${KVSTORE_RETRIES:-5}"
KVSTORE_RETRY_DELAY_SECONDS="${KVSTORE_RETRY_DELAY_SECONDS:-2}"
INTEGRATION_MAKE_TARGET="${INTEGRATION_MAKE_TARGET:-integration-tests}"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
USE_PODMAN_MTU_WORKAROUND="${USE_PODMAN_MTU_WORKAROUND:-true}"
KVSTORE_NETWORK_NAME="${KVSTORE_NETWORK_NAME:-cilium-etcd-net}"
KVSTORE_NETWORK_MTU="${KVSTORE_NETWORK_MTU:-1500}"

# Some z hosts expect this in shell startup.
export BASHRCSOURCED="${BASHRCSOURCED:-1}"

cleanup() {
  "${CONTAINER_ENGINE}" rm -f cilium-etcd-test-container >/dev/null 2>&1 || true
}

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

trap cleanup EXIT

cd "${ROOT_DIR}"

engine_version="$("${CONTAINER_ENGINE}" --version 2>/dev/null || true)"
engine_version_lc="$(printf '%s' "${engine_version}" | tr '[:upper:]' '[:lower:]')"
is_podman=false
if [[ "${engine_version_lc}" == *podman* ]]; then
  is_podman=true
fi

attempt=0
started=false
start_kvstores_args=(start-kvstores)
if [[ "${is_podman}" == "true" && "${USE_PODMAN_MTU_WORKAROUND}" == "true" ]]; then
  log "Using podman MTU workaround network ${KVSTORE_NETWORK_NAME} (mtu=${KVSTORE_NETWORK_MTU})"
  start_kvstores_args+=(
    "KVSTORE_USE_PODMAN_MTU_WORKAROUND=true"
    "KVSTORE_NETWORK_NAME=${KVSTORE_NETWORK_NAME}"
    "KVSTORE_NETWORK_MTU=${KVSTORE_NETWORK_MTU}"
  )
fi
while (( attempt < KVSTORE_RETRIES )); do
  attempt=$((attempt + 1))
  log "Starting kvstore via make start-kvstores (attempt ${attempt}/${KVSTORE_RETRIES})"
  if "${MAKE_BIN}" "${start_kvstores_args[@]}"; then
    started=true
    break
  fi
  sleep "${KVSTORE_RETRY_DELAY_SECONDS}"
done

if [[ "${started}" != "true" ]]; then
  echo "Failed to start kvstore after ${KVSTORE_RETRIES} attempts" >&2
  exit 1
fi

log "Running ${INTEGRATION_MAKE_TARGET} with SKIP_KVSTORES=true"
SKIP_KVSTORES=true "${MAKE_BIN}" "${INTEGRATION_MAKE_TARGET}"
log "Integration sweep completed"
