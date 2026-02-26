#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SMOKE_RC=0
POLICY_RC=0
BPF_SUBSET_RC=0
RUN_POLICY_INTEGRATION="${RUN_POLICY_INTEGRATION:-false}"
RUN_BPF_REGRESSION_SUBSET="${RUN_BPF_REGRESSION_SUBSET:-false}"

"${SCRIPT_DIR}/deploy_cilium_s390x.sh"
"${SCRIPT_DIR}/smoke_status.sh" || SMOKE_RC=$?

if [[ "${RUN_POLICY_INTEGRATION}" == "true" && "${SMOKE_RC}" -eq 0 ]]; then
  "${SCRIPT_DIR}/policy_integration.sh" || POLICY_RC=$?
elif [[ "${RUN_POLICY_INTEGRATION}" == "true" ]]; then
  echo "Skipping policy integration because smoke checks failed" >&2
fi

if [[ "${RUN_BPF_REGRESSION_SUBSET}" == "true" && "${SMOKE_RC}" -eq 0 ]]; then
  "${SCRIPT_DIR}/bpf_regression_subset.sh" || BPF_SUBSET_RC=$?
elif [[ "${RUN_BPF_REGRESSION_SUBSET}" == "true" ]]; then
  echo "Skipping BPF regression subset because smoke checks failed" >&2
fi

"${SCRIPT_DIR}/collect_artifacts.sh"

if [[ "${SMOKE_RC}" -ne 0 ]]; then
  echo "Smoke checks failed; artifacts still collected" >&2
  exit "${SMOKE_RC}"
fi

if [[ "${POLICY_RC}" -ne 0 ]]; then
  echo "Policy integration checks failed; artifacts still collected" >&2
  exit "${POLICY_RC}"
fi

if [[ "${BPF_SUBSET_RC}" -ne 0 ]]; then
  echo "BPF regression subset failed; artifacts still collected" >&2
  exit "${BPF_SUBSET_RC}"
fi
