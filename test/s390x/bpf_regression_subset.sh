#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

BPF_TEST_MAKE_DIR="${BPF_TEST_MAKE_DIR:-${ROOT_DIR}/bpf/tests}"
BPF_STACK_SIZE="${BPF_STACK_SIZE:-1024}"
BPF_REGRESSION_TESTS="${BPF_REGRESSION_TESTS:-tc_lxc_policy_drop tc_policy_reject_response_test hairpin_sctp_flow}"

check_python_deps() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for BPF regression tests" >&2
    return 1
  fi

  if ! python3 - <<'PY' >/dev/null 2>&1
import jinja2
from scapy.all import Ether
PY
  then
    cat >&2 <<'EOF'
Missing Python modules for BPF regression tests: jinja2 and/or scapy.
Install prerequisites before rerunning.
- RHEL/Fedora: dnf install -y python3-jinja2 python3-scapy
- Debian/Ubuntu: apt-get install -y python3-jinja2 python3-scapy
EOF
    return 1
  fi
}

FAILED=()

check_python_deps

for test_name in ${BPF_REGRESSION_TESTS}; do
  echo "Running BPF regression test: ${test_name}"
  if ! make -C "${BPF_TEST_MAKE_DIR}" run BPF_STACK_SIZE="${BPF_STACK_SIZE}" BPF_TEST="${test_name}"; then
    FAILED+=("${test_name}")
  fi
done

if ((${#FAILED[@]} > 0)); then
  echo "BPF regression subset failed: ${FAILED[*]}" >&2
  exit 1
fi

echo "BPF regression subset passed"
