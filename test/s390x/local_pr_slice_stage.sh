#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  cat >&2 <<'EOF'
usage: test/s390x/local_pr_slice_stage.sh <slice>

slices:
  bpf-datapath
  bpf-tests
  go-tests
  harness
  build-tooling
  docs-local
EOF
  exit 1
fi

slice="$1"

add_path() {
  local p="$1"
  if [[ -e "${p}" ]] || git ls-files --error-unmatch -- "${p}" >/dev/null 2>&1; then
    git add -A -- "${p}"
  else
    printf 'skip (missing): %s\n' "${p}" >&2
  fi
}

case "${slice}" in
  bpf-datapath)
    add_path bpf/lib/hash.h
    add_path bpf/lib/ip_options.h
    add_path bpf/lib/ipv4.h
    add_path bpf/lib/lb.h
    add_path bpf/lib/policy.h
    add_path bpf/tests/lib/policy.h
    ;;
  bpf-tests)
    add_path bpf/tests/Makefile
    add_path bpf/tests/bpftest/bpf_test.go
    add_path bpf/tests/builtin_test.h
    add_path bpf/tests/common.h
    add_path bpf/tests/lib/egressgw_policy.h
    add_path bpf/tests/pktgen.h
    add_path bpf/tests/tc_egressgw_redirect_from_host.c
    add_path bpf/tests/tc_egressgw_redirect_from_overlay.c
    add_path bpf/tests/tc_egressgw_redirect_from_overlay_with_egress_interface.c
    add_path bpf/tests/tc_egressgw_snat.c
    add_path bpf/tests/tc_lxc_lb4_no_backend.c
    add_path bpf/tests/tc_lxc_lb6_no_backend.c
    add_path bpf/tests/tc_nodeport_lb4_dsr_lb.c
    add_path bpf/tests/tc_nodeport_lb4_no_backend.c
    add_path bpf/tests/tc_nodeport_lb6_no_backend.c
    add_path bpf/tests/tc_nodeport_test.c
    add_path bpf/tests/xdp_egressgw_reply.c
    add_path bpf/tests/xdp_nodeport_lb4_dsr_lb.c
    add_path bpf/tests/xdp_nodeport_lb4_test.c
    ;;
  go-tests)
    add_path pkg/act/act_test.go
    add_path pkg/bpf/collection_test.go
    add_path pkg/bpf/collection_endian_test.go
    add_path pkg/bpf/unused_maps_test.go
    add_path pkg/datapath/iptables/iptables_test.go
    add_path pkg/datapath/neighbor/test/script_test.go
    add_path pkg/datapath/sockets/sockets_test.go
    add_path pkg/hubble/parser/debug/parser_test.go
    add_path pkg/hubble/parser/threefour/parser_test.go
    add_path pkg/hubble/testutils/payload_test.go
    add_path pkg/testutils/scriptnet/scriptnet.go
    ;;
  harness)
    add_path test/s390x
    add_path test/Makefile
    add_path test/README.md
    ;;
  build-tooling)
    add_path Makefile
    add_path Makefile.defs
    add_path go.sum
    add_path images/Makefile
    add_path images/builder/Dockerfile
    add_path images/builder/install-protoc.sh
    add_path images/builder/test/spec.yaml
    add_path images/scripts/build-image.sh
    add_path images/scripts/make-image-tag.sh
    ;;
  docs-local)
    add_path docs/s390x-upstream-issue-pr-drafts.md
    add_path docs/s390x/README.md
    add_path docs/s390x/reporting-flow.md
    add_path docs/s390x/zkd0-build-journal-2026-02-20.md
    add_path docs/s390x/zkd0-build-journal-2026-02-21.md
    add_path docs/s390x/zkd0-build-journal-2026-02-22.md
    add_path docs/s390x/zkd0-build-journal-2026-02-23.md
    add_path docs/s390x/zkd0-build-journal-2026-02-24.md
    add_path docs/s390x/zkd0-build-journal-2026-02-25.md
    add_path docs/s390x/logs/2026-02-25/RUN-INDEX.md
    ;;
  *)
    echo "unknown slice: ${slice}" >&2
    exit 1
    ;;
esac

echo
echo "Staged files for slice: ${slice}"
git diff --cached --name-only
