#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

HARNESS_SCRIPT="${HARNESS_SCRIPT:-${ROOT_DIR}/test/s390x/run_harness.sh}"
RUN_ID="${RUN_ID:-adhoc}"
RUN_COMPONENT="${RUN_COMPONENT:-s390x-harness}"
RUN_DAY="${RUN_DAY:-$(date -u +%F)}"
RUN_TS="${RUN_TS:-$(date -u +%Y%m%dT%H%M%SZ)}"
LOG_DIR="${LOG_DIR:-${ROOT_DIR}/docs/s390x/logs/${RUN_DAY}}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/${RUN_COMPONENT}-${RUN_ID}-${RUN_TS}.log}"
STATUS_FILE="${STATUS_FILE:-${LOG_DIR}/${RUN_COMPONENT}-${RUN_ID}-${RUN_TS}.status}"

if [[ ! -x "${HARNESS_SCRIPT}" ]]; then
  echo "Harness script is not executable: ${HARNESS_SCRIPT}" >&2
  exit 1
fi

mkdir -p "${LOG_DIR}"

STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo "[INFO] ${STARTED_AT} start ${RUN_COMPONENT} ${RUN_ID}"
  echo "[INFO] host=$(hostname -f 2>/dev/null || hostname)"
  echo "[INFO] root_dir=${ROOT_DIR}"
  echo "[INFO] git_rev=$(git -C "${ROOT_DIR}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo "[INFO] harness_script=${HARNESS_SCRIPT}"
  echo "[INFO] command=${HARNESS_SCRIPT} $*"
} >> "${LOG_FILE}"

set +e
"${HARNESS_SCRIPT}" "$@" >> "${LOG_FILE}" 2>&1
RC=$?
set -e

ENDED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "[INFO] ${ENDED_AT} end rc=${RC}" >> "${LOG_FILE}"

cat > "${STATUS_FILE}" <<EOF
run=${RUN_ID}
component=${RUN_COMPONENT}
host=$(hostname -f 2>/dev/null || hostname)
started_at=${STARTED_AT}
ended_at=${ENDED_AT}
rc=${RC}
log=${LOG_FILE}
harness_script=${HARNESS_SCRIPT}
EOF

printf 'log=%s\nstatus=%s\nrc=%s\n' "${LOG_FILE}" "${STATUS_FILE}" "${RC}"
exit "${RC}"
