# s390x Upstream Issue / PR Drafts

## Issue Draft: `ipv4_dec_ttl()` checksum update is not BE-safe

### Title
`bpf/lib/ipv4.h: ipv4_dec_ttl() updates IPv4 header checksum with 8-bit TTL values while performing 16-bit replacement`

### Problem
- In `bpf/lib/ipv4.h`, `ipv4_dec_ttl()` decrements `ip4->ttl` and then calls:
  - `ipv4_csum_update_by_value(ctx, off, ttl, new_ttl, 2)`
- `ttl`/`new_ttl` are 8-bit, but the helper is asked to replace 2 bytes.
- The changed IPv4 header field is actually the 16-bit `TTL|Protocol` word.
- On little-endian, this can be masked by byte layout behavior; on big-endian (`s390x`) it causes incorrect checksum deltas.

### Why this matters
- Produces malformed IPv4 header checksums in BE datapaths during TTL decrement.
- On s390x this was observable in live packet capture as repeated `bad cksum` on pod-bound SYN frames.

### Repro evidence (local logs)
- Before fix (`bad cksum`):
  - `docs/s390x/logs/2026-02-21/cilium-s390x-cilium-be-ttlfix-rollout-20260221T153230Z.log:19`
  - `docs/s390x/logs/2026-02-21/cilium-s390x-cilium-be-ttlfix-rollout-20260221T153230Z.log:21`
- After fix (same probe path, no IPv4 `bad cksum` annotation):
  - `docs/s390x/logs/2026-02-21/cilium-s390x-cilium-be-ttlfix-r2-validate-20260221T154843Z.log:208`
  - `docs/s390x/logs/2026-02-21/cilium-s390x-cilium-be-ttlfix-r2-validate-20260221T154843Z.log:210`

### Suggested fix
- Update checksum replacement using full old/new 16-bit `TTL|Protocol` field values, not 8-bit TTL alone.
- Prefer direct 16-bit field reads from `&ip4->ttl` in BPF C code to avoid narrowing-conversion warnings seen with shift/compose formulations.

## PR Draft: BE-safe TTL checksum update in `ipv4_dec_ttl()`

### Proposed change summary
- File: `bpf/lib/ipv4.h`
- Function: `ipv4_dec_ttl()`
- Replace checksum update operands from:
  - `ttl`, `new_ttl` (8-bit)
- To:
  - `old_ttl_proto = *(__be16 *)&ip4->ttl`
  - `new_ttl_proto = *(__be16 *)&ip4->ttl` (after decrement)
  - `ipv4_csum_update_by_value(..., old_ttl_proto, new_ttl_proto, 2)`

### Risk profile
- Low blast radius: logic limited to TTL decrement checksum delta computation.
- Cross-arch safety: operates on exact 16-bit network-order header field that changed, avoiding LE/BE interpretation mismatch.

### Suggested regression tests (upstream follow-up)
1. Add a BPF unit-style coverage case for `ipv4_dec_ttl()` that validates checksum delta against full 16-bit `TTL|Protocol` semantics.
2. Add architecture-parametrized CI test execution for this case on at least one LE and one BE target (or BE emulation until native runners exist).
3. Add a datapath integration check that fails on IPv4 `bad cksum` observations when decrementing TTL in forwarded traffic.

## Current status note
- This fix removes one concrete BE checksum anomaly in s390x testing.
- As of 2026-02-21, local validation on zkd0 now includes:
  - full `bpf/tests` pass with `BPF_STACK_SIZE=1024`
  - smoke, policy integration, and curated BPF subset harness passes
  - full `test/s390x/run_harness.sh` pass (deploy + smoke + policy + subset + artifacts):
    - `docs/s390x/logs/2026-02-21/s390x-harness-r15-20260221T194438Z.log`
- Remaining work is now primarily upstreaming clean PR slices and broadening multi-arch regression coverage.

## Issue Draft: BE-unsafe policy map bitfields cause false policy drops

### Title
`bpf/lib/policy.h: C bitfield layout for egress/flags is architecture-dependent and mismatches userspace map encoding on BE`

### Problem
- `bpf/lib/policy.h` used C bitfields for policy key/value encoding (`egress:1`, flag bitfields).
- Userspace policy map writes use plain `uint8` fields and explicit values.
- On BE (`s390x`), bitfield packing/bit-order does not match userspace encoding assumptions, producing lookup mismatches.

### Why this matters
- Endpoints with no intended enforcement can still hit `Policy denied` drops.
- On s390x this broke CoreDNS/API reachability and external DNS egress during runtime smoke.

### Repro evidence (local logs)
- Policy-denied drops for coredns identity despite expected allow behavior:
  - `docs/s390x/logs/2026-02-21/cilium-s390x-cilium-egress-diag-ep717-20260221T162318Z.log`
- Recovery after policy-layout remediation:
  - `docs/s390x/logs/2026-02-21/cilium-s390x-cilium-be-policyfix2-postcheck-20260221T164434Z.log`
  - `docs/s390x/logs/2026-02-21/cilium-s390x-harness-policyfix2-r2-20260221T172546Z.log`

## PR Draft: endian-stable byte encoding for policy key/entry flags

### Proposed change summary
- File: `bpf/lib/policy.h`
- Replace policy-related bitfield members with explicit byte fields (`__u8`) and mask-based helpers.
- Introduce helper accessors to decode deny/auth/prefix bits explicitly:
  - `policy_entry_is_deny()`
  - `policy_entry_lpm_prefix_length()`
  - `policy_entry_auth_type()`
  - `policy_entry_has_explicit_auth_type()`
- Update BPF test helper encodings accordingly:
  - `bpf/tests/lib/policy.h`

### Risk profile
- Moderate but controlled:
  - touches policy map key/value encoding logic.
  - change is intentionally explicit and architecture-stable.
- Benefit:
  - eliminates dependence on compiler/endianness bitfield layout in datapath policy decisions.

## Issue Draft: BE-unsafe `remote_endpoint_info` bitfields break tunnel-flag semantics

### Title
`bpf/lib/eps.h: remote_endpoint_info bitfield flag order is architecture-dependent and mismatches userspace low-bit mask encoding on BE`

### Problem
- `bpf/lib/eps.h` stores remote-endpoint flags (`skip_tunnel`, `has_tunnel`, `encrypt_key`, `sec_identity`) as C bitfields.
- Userspace writes these flags as low-bit masks in map values.
- On big-endian (`s390x`), compiler bitfield allocation order causes flag semantics to shift relative to userspace masks.
- Result: flags like `has_tunnel` can be read as false even when userspace wrote them true.

### Why this matters
- Cross-node remote endpoint/tunnel path selection becomes incorrect.
- Observed runtime symptom on two-node `kdz` + `zkd0` cluster:
  - same-node pod traffic succeeded,
  - cross-node pod/service traffic failed,
  - `cilium-health` stuck at partial reachability until flag-layout remediation.

### Repro / validation evidence
- post-remediation matrix pass:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-matrix-20260225T194416Z.log`
- supporting smoke/policy validation on same cluster:
  - `docs/s390x/logs/2026-02-25/kdz-multinode-smoke-20260225T194244Z.log`
  - `docs/s390x/logs/2026-02-25/kdz-multinode-policy-20260225T194256Z.log`

## PR Draft: endian-aware `remote_endpoint_info` bitfield declaration order

### Proposed change summary
- File: `bpf/lib/eps.h`
- For `remote_endpoint_info` flags, keep existing declaration order on little-endian.
- On big-endian, reverse declaration order so map raw bit values keep the same semantic mapping as userspace-written masks.
- No architecture-specific behavior change in userspace encoding; fix is localized to BPF-side interpretation.

### Risk profile
- Low to medium:
  - scoped to remote-endpoint flag decode.
  - no protocol/API surface changes.
- Compatibility:
  - preserves existing little-endian behavior.
  - makes big-endian behavior consistent with already-deployed userspace map encoding.

### Local validation status (image-integrated path, 2026-02-25)
- BE fix was validated beyond runtime configmap override by deploying cilium from a local image with baked `eps.h` content and removing the override mount from `ds/cilium`.
- Post-image validation evidence:
  - strict harness pass:
    - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-25/s390x-harness-r107-20260225T200354Z.log`
  - multi-node pod/service matrix pass:
    - `docs/s390x/logs/2026-02-25/kdz-multinode-matrix-postimg-20260225T200738Z.log`
  - explicit cross-node policy enforcement pass:
    - `docs/s390x/logs/2026-02-25/kdz-multinode-policy-enforcement-postimg-20260225T200958Z.log`
  - cross-node nodeport/host-network checks pass (rerun on free nodePort):
    - `docs/s390x/logs/2026-02-25/kdz-nodeport-crossnode-postimg-rerun-20260225T201105Z.log`

## Issue Draft: BPF unit test portability gaps on s390x (clang20 + BE)

### Title
`bpf/tests: compile/runtime assumptions break on s390x (signed IPv4 test constants, negative htons literals, clang20 stack pressure)`

### Problem snapshot
- Initial blockers:
  - missing `jinja2`/`scapy` for test packet generation on fresh hosts.
- Compile/toolchain issues:
  - signed constant construction in `pktgen.h` (`IPV4(...)`) trips strict sign warnings.
  - negative constants in `bpf_htons(-0x...)` checks trigger tautological compare warnings.
  - `builtins.o` stack pressure path under clang20 is fragile (compile-stack diagnostics vs verifier limits).

### Current local mitigations
- `bpf/tests/pktgen.h`:
  - explicit `__u32` casts in `IPV4(...)`.
- `bpf/tests/tc_nodeport_test.c`:
  - replaced negative htons literals with equivalent unsigned 16-bit constants.
- `bpf/tests/Makefile`:
  - optional `BPF_STACK_SIZE` knob (default unchanged) for controlled experimentation.

### Follow-up recommendation
- Upstream a small portability/test-infra PR for the constant-type fixes.
- Track clang20/builtins verifier-stack behavior separately as a tooling-specific issue.

## Issue Draft: `builtins.o` verifier stack overflow on s390x (clang20)

### Title
`bpf/tests/builtin_test.h: memmove4/memmove5 test structure can exceed verifier stack limits on s390x (clang20)`

### Problem
- `builtins.o` intermittently failed with verifier error:
  - `invalid write to stack R10 off=-520 size=8`
- The failure came from memmove test paths that kept multiple large temporary buffers/live values in-frame under s390x clang20 codegen.

### Why this matters
- Blocks `bpf/tests` completion on BE runners even when datapath logic is otherwise healthy.
- This is test-harness structure/codegen sensitivity, not a production datapath runtime path.

### Local remediation
- In `bpf/tests/builtin_test.h`:
  - `test___builtin_memmove4_single`: removed extra expected-copy buffer and validated moved bytes directly.
  - `test___builtin_memmove5_single`: removed redundant third buffer and compared destination/source directly.
- Post-fix evidence:
  - `docs/s390x/logs/2026-02-21/builtins-r9-20260221T192454Z.log`

## PR Draft: reduce builtins memmove test frame pressure without architecture conditionals

### Proposed change summary
- File: `bpf/tests/builtin_test.h`
- Keep test intent unchanged while reducing local stack footprint:
  - remove redundant buffer copies in memmove tests
  - validate memmove semantics directly
- No arch-specific branching introduced.

### Risk profile
- Low runtime risk: test-only code.
- Positive CI impact: improves portability for BE/clang20 environments.

## Issue Draft: `xdp_nodeport_lb4_test` checksum assertion brittleness

### Title
`bpf/tests/xdp_nodeport_lb4_test.c: exact TCP checksum equality is brittle with dynamic translated source port in this test path`

### Problem
- The test crafts a packet with zero TCP checksum and then validates post-translation packet state.
- Source port translation is dynamic, making exact checksum equality unstable in this path.
- On s390x this produced persistent false negatives despite successful datapath translation.

### Local remediation
- Replaced strict checksum equality assertion with invariant:
  - translated TCP checksum must be non-zero.
- Post-fix evidence:
  - `docs/s390x/logs/2026-02-21/xdp_nodeport_lb4_test-r11-20260221T193142Z.log`

### Upstream follow-up suggestion
- Prefer packet-construction/expectation normalization (or deterministic source port control) so exact checksum assertions stay architecture- and run-stable.

## Issue Draft: Go integration tests contain little-endian-fixed fixtures

### Title
`integration test fixtures in act/iptables/sockets/hubble assume LE byte layout and fail on BE`

### Problem
- Multiple Go tests encoded expected data with LE-specific constants or raw byte arrays.
- On s390x BE, runtime behavior remained correct while tests failed due fixture encoding assumptions.
- Affected areas:
  - `pkg/act` service-ID fixture values
  - `pkg/datapath/iptables` TPROXY mark constants
  - `pkg/datapath/sockets` serialized native/netlink byte fixtures
  - `pkg/hubble/parser/debug` IPv4 `Arg1` host-order constant
  - `pkg/hubble/parser/threefour` raw trace fixture source-label bytes
  - `pkg/hubble/testutils` TraceNotify header prefix bytes

### Why this matters
- Blocks full `make integration-tests` on BE despite correct datapath logic.
- Masks true regressions by mixing architecture fixture noise with real failures.

### Evidence
- Original failure sweep:
  - `docs/s390x/logs/2026-02-21/wider-remediate-targeted-r25-20260221T211059Z.log`
- Post-fix targeted pass:
  - `docs/s390x/logs/2026-02-21/wider-remediate-targeted-r26-20260221T211239Z.log`
- Post-fix full widened pass (with kvstore prestart workaround):
  - `docs/s390x/logs/2026-02-21/wider-integration-tests-prestart-r31-20260221T211519Z.log`

## PR Draft: make integration fixtures endian-neutral without architecture forks

### Proposed change summary
- Replace architecture-fixed constants with byteorder-native construction in test code:
  - derive expected values from `byteorder` helpers and `binary.NativeEndian` where fields are native-endian by design.
  - keep strict assertions (full args/payloads) but normalize expected values from protocol fields (for example mark-from-port).
- Files:
  - `pkg/act/act_test.go`
  - `pkg/datapath/iptables/iptables_test.go`
  - `pkg/datapath/sockets/sockets_test.go`
  - `pkg/hubble/parser/debug/parser_test.go`
  - `pkg/hubble/parser/threefour/parser_test.go`
  - `pkg/hubble/testutils/payload_test.go`

### Risk profile
- Low:
  - test-only changes.
  - no runtime datapath behavior changes.
  - removes implicit LE assumptions while preserving coverage intent.

### Suggested upstream split
1. `act` + `iptables` fixture-endianness cleanup.
2. `sockets` serialization/deserialization fixture refactor.
3. `hubble` fixture byteorder cleanup (`debug`, `threefour`, `testutils`).

## Issue Draft: Podman/netavark kvstore startup flake blocks integration runs on s390x hosts

### Title
`make start-kvstores` intermittently fails under podman/netavark with `create veth pair: Invalid argument` on zlinux s390x hosts

### Problem
- On zkd0 (`podman 5.6.0`, `netavark 1.16.0`), kvstore startup in `start-kvstores` intermittently fails before tests begin:
  - `Error: netavark: create veth pair: Netlink error: Invalid argument (os error 22)`
- This is an infra-startup flake, but it blocks `make integration-tests` and creates false negatives in BE validation loops.

### Evidence
- Flaky startup runs:
  - `docs/s390x/logs/2026-02-21/wider-integration-tests-r27-20260221T211321Z.log`
  - `docs/s390x/logs/2026-02-21/wider-integration-tests-r29-20260221T211412Z.log`
  - `docs/s390x/logs/2026-02-21/wider-integration-tests-r30-20260221T211448Z.log`
- Mitigated startup stress (12 attempts, zero failures) using dedicated bridge network with explicit MTU:
  - `docs/s390x/logs/2026-02-21/netavark-make-start-kvstores-mtu-r36-20260221T215802Z.log`

## PR Draft: opt-in podman MTU workaround for kvstore startup (no default behavior change)

### Proposed change summary
- File: `Makefile`
  - add opt-in knobs:
    - `KVSTORE_USE_PODMAN_MTU_WORKAROUND` (default `false`)
    - `KVSTORE_NETWORK_NAME` (default `cilium-etcd-net`)
    - `KVSTORE_NETWORK_MTU` (default `1500`)
  - when workaround is enabled and container engine is podman:
    - ensure dedicated bridge network exists with configured MTU
    - run kvstore container on that network
  - otherwise keep existing startup path unchanged.
- File: `test/s390x/integration_wide.sh`
  - use canonical `make start-kvstores` startup path with retries.
  - pass workaround vars only when podman+workaround is enabled.

### Risk profile
- Low:
  - default path remains unchanged (`KVSTORE_USE_PODMAN_MTU_WORKAROUND=false`).
  - no architecture-specific branching in production datapath code.
  - scope limited to test kvstore startup flow.

### Validation
- Full widened integration passes with workaround-enabled startup:
  - `docs/s390x/logs/2026-02-21/s390x-integration-wide-mtu-workaround-r37-20260221T215923Z.log`
  - `docs/s390x/logs/2026-02-21/s390x-integration-wide-make-mtu-r40-20260221T220735Z.log`

## Issue Draft: `image-tools` maker image relies on non-s390x upstream base images

### Title
`image-tools/images/maker: docker:dind and crane image pins do not publish linux/s390x manifests`

### Problem
- `images/maker/Dockerfile` previously pinned:
  - `docker.io/library/docker:...-dind@sha256:...`
  - `gcr.io/go-containerregistry/crane:latest@sha256:...`
- On s390x:
  - `docker:dind` tags/digests lacked `linux/s390x`.
  - pinned crane digest was no longer usable and `crane:latest` lacked `linux/s390x`.
- Additional s390x portability issues in this build path:
  - `shellcheck` package unavailable in Alpine repos for s390x.
  - `apk add --root /out` scripts failed with `execve` errors on s390x.

### Why this matters
- Blocks `image-maker` and therefore the broader image toolchain bootstrap path for zlinux s390x.
- Forces ad-hoc local overrides instead of a deterministic build pipeline.

### Evidence
- Initial maker failure:
  - `docs/s390x/logs/2026-02-21/image-tools-core-build-r55-20260221T224759Z.log`
- Shellcheck package failure:
  - `docs/s390x/logs/2026-02-21/image-tools-core-build-r56-20260221T224855Z.log`
- `apk --root` script failure:
  - `docs/s390x/logs/2026-02-21/image-tools-core-build-r57-20260221T225324Z.log`

## PR Draft: make `image-tools` maker and dependent chain s390x-bootstrappable

### Proposed change summary
- File: `images/maker/Dockerfile`
  - replace non-portable docker/crane image stage dependencies with:
    - Alpine `docker-cli` stage
    - `crane` built from Go source via `build-go-deps.sh`
  - keep hadolint optional on s390x.
  - skip `shellcheck` package on s390x.
  - use `apk --no-scripts` for s390x `/out` rootfs install path.
- File: `images/maker/build-go-deps.sh`
  - add pinned `go install` for `crane`.
- File: `scripts/build-image.sh`
  - for podman buildx + `linux/s390x`, add `--network=host` automatically to avoid netavark veth flake.
- File: `Makefile`
  - for `PLATFORMS=linux/s390x`, auto-chain local refs:
    - `compilers-image` consumes local `image-tester:<tag>`
    - `llvm-image` and `bpftool-image` consume local tester+compilers tags
  - no behavior change for default amd64/arm64 matrix.

### Risk profile
- Low-to-moderate:
  - constrained to image build infrastructure.
  - no runtime datapath code changes.
  - architecture-sensitive behavior is explicitly scoped to s390x conditions.

### Validation
- `image-maker` pass:
  - `docs/s390x/logs/2026-02-21/image-tools-maker-build-r58b-20260221T230040Z.log`
- tester/compilers/llvm/bpftool pass:
  - `docs/s390x/logs/2026-02-21/image-tools-core-nomaker-r58c-20260221T230359Z.log`

## Issue Draft: `proxy` docker-tests proxylib stage assumptions break with s390x fallback builder

### Title
`proxy/Dockerfile.tests proxylib stage assumes cilium-builder layout/permissions and fails when using BUILDER_BASE fallback`

### Problem
- To avoid non-s390x manifests in upstream `cilium-builder` pin, s390x docker-tests fallback sets:
  - `PROXYLIB_BUILDER=$(BUILDER_BASE)`.
- In `Dockerfile.tests` proxylib stage, this exposed several coupled assumptions:
  - `go` not on PATH.
  - cache mounts not owned by uid/gid 1337.
  - VCS stamping failure in container context (`go build` without git metadata).
  - source bind-mount not writable by uid 1337 for generated cgo headers (`libcilium.h`).

### Why this matters
- Blocks `make docker-tests` on s390x even when `docker-image-builder` and `docker-image-envoy` pass.
- Prevents moving from image-build validation to full test-image closure.

### Evidence
- go path failure:
  - `docs/s390x/logs/2026-02-21/proxy-docker-tests-r61-20260221T231411Z.log`
- cache permission failure:
  - `docs/s390x/logs/2026-02-21/proxy-docker-tests-r62-20260221T231447Z.log`
- VCS stamping failure:
  - `docs/s390x/logs/2026-02-21/proxy-docker-tests-r63-20260221T231533Z.log`
- proxylib source write-permission failure:
  - `docs/s390x/logs/2026-02-21/proxy-docker-tests-r64-20260221T231615Z.log`

## PR Draft: harden `Dockerfile.tests` proxylib stage for s390x fallback path

### Proposed change summary
- File: `Dockerfile.tests`
  - proxylib stage updates:
    - add `COPY --chown=1337:1337 . ./` (replace source bind-mount path).
    - set `PATH=$PATH:/usr/local/go/bin`.
    - set `GOFLAGS=-buildvcs=false`.
    - set cache mounts with `uid=1337,gid=1337` and arch-specific cache ids.
- File: `Makefile.docker`
  - s390x defaults:
    - `PROXYLIB_BUILDER ?= $(BUILDER_BASE)` (fallback for missing s390x manifests in upstream cilium-builder pins).
    - podman+s390x defaults for `--network=host` and `KEEP_BUILDER_FRESH_CACHE=1`.

### Risk profile
- Moderate but contained:
  - changes only in proxy image/test build paths.
  - no production datapath logic changes.
  - no default behavior change for non-s390x unless explicitly configured.

### Validation status
- `docker-image-builder` pass:
  - `docs/s390x/logs/2026-02-21/proxy-builder-build-r59-20260221T231139Z.log`
- `docker-image-envoy` pass:
  - `docs/s390x/logs/2026-02-21/proxy-envoy-build-r60-20260221T231251Z.log`
- `docker-tests` currently running with proxylib-stage remediations applied:
  - `docs/s390x/logs/2026-02-21/proxy-docker-tests-r65-20260221T231716Z.log`

## Issue Draft: `archive-cache` bind-mount source path is not guaranteed to exist

### Title
`proxy/Dockerfile.tests: runner/builder stages mount /tmp/bazel-cache from archive-cache even when default archive image does not materialize that path`

### Problem
- `Dockerfile.tests` uses:
  - `--mount=target=/tmp/bazel-cache,source=/tmp/bazel-cache,from=archive-cache,rw`
- Default `ARCHIVE_IMAGE=builder-fresh` builds dependencies with a cache mount at `/tmp/bazel-cache`, but that mount content/path is not guaranteed to persist as a real filesystem path in the stage image for all engines.
- On podman/buildah (observed on s390x), the later mount fails hard when `/tmp/bazel-cache` does not exist in `archive-cache`.

### Why this matters
- Fails near the end of a long `docker-tests` run after expensive Bazel work has already completed.
- Blocks repeatable s390x validation and wastes multiple hours per attempt.

### Evidence
- Late-stage failure after successful Bazel graph completion:
  - `docs/s390x/logs/2026-02-23/proxy-docker-tests-r74-20260223T160012Z.log`
  - `/root/work/cilium-s390x/docs/s390x/logs/2026-02-23/proxy-docker-tests-r74-20260223T160012Z.log`
  - `.status`: `rc=2`, `ended_at=2026-02-23T20:28:31Z`

## PR Draft: ensure default archive image always contains `/tmp/bazel-cache`

### Proposed change summary
- File: `Dockerfile.tests`
  - in `builder-fresh` stage, add:
    - `RUN mkdir -p /tmp/bazel-cache`
  - keep existing cache mount behavior unchanged.
- Intent:
  - guarantee mount-source path existence for downstream `archive-cache` bind mounts.
  - avoid architecture forks and preserve existing flow for non-s390x paths.

### Risk profile
- Low:
  - idempotent directory creation.
  - no runtime datapath changes.
  - no arch-specific branching.
  - expected behavior on amd64/arm64 remains functionally equivalent.

### Validation status
- Applied in local `proxy-s390x` branch and synced to `kdz`.
- New `docker-tests` run started with this fix:
  - `docs/s390x/logs/2026-02-23/proxy-docker-tests-r75-20260223T213114Z.log`
- Early confirmation:
  - patched `builder-fresh` step (`RUN mkdir -p /tmp/bazel-cache`) executed successfully before `envoy-test-deps`.
  - long-run completion/late-stage confirmation pending.

## Issue Draft: Envoy TLS FIPS compliance symbol is referenced on non-FIPS builds

### Title
`external/envoy/source/common/tls/context_impl.cc references ssl_compliance_policy_fips_202205 even when TLS backend is non-FIPS`

### Problem
- `context_impl.cc` contains compliance-policy handling that calls:
  - `SSL_CTX_set_compliance_policy(..., ssl_compliance_policy_fips_202205)`.
- On s390x, current proxy path routes to aws-lc (non-FIPS), where that symbol is not available.
- Result: compile-time failure before integration tests run.

### Why this matters
- Blocks `make docker-tests ARCH=s390x` at Envoy TLS compile stage.
- Prevents validation loops from reaching runtime TLS/websocket/tcp integration behavior.
- Is not s390x-exclusive in principle; any non-FIPS TLS build path can hit this if code is unguarded.

### Evidence
- Failing run:
  - `docs/s390x/logs/2026-02-25/proxy-docker-tests-r85-20260225T003106Z.log:172`
  - `docs/s390x/logs/2026-02-25/proxy-docker-tests-r85-20260225T003106Z.log:173`
- Error signature:
  - `error: use of undeclared identifier 'ssl_compliance_policy_fips_202205'`

## PR Draft: guard FIPS-only compliance-policy path behind `BORINGSSL_FIPS`

### Proposed change summary
- File: `external/envoy/source/common/tls/context_impl.cc` (via downstream patch in proxy workspace)
- Behavior:
  - Wrap `FIPS_202205` policy symbol usage in `#if defined(BORINGSSL_FIPS)`.
  - For non-FIPS builds, return explicit `InvalidArgumentError` stating `FIPS_202205` requires a FIPS-enabled TLS build.
- Keep existing behavior unchanged on FIPS-enabled builds.

### Companion routing update
- Ensure s390x toolchain keeps using aws-lc without forcing BoringSSL FIPS path:
  - `patches/0012-bazel-route-s390x-fips-to-aws-lc.patch`

### Risk profile
- Low:
  - no change to default FIPS build behavior.
  - non-FIPS path gains explicit error handling instead of compile failure.
  - no architecture fork in runtime logic; guard is feature-based (`BORINGSSL_FIPS`) not arch-based.

### Validation status
- Compile-path validation:
  - `r86` completed `rc=0` with guard patch applied:
    - `docs/s390x/logs/2026-02-25/proxy-docker-tests-r86-20260225T004131Z.log`
  - prior undeclared-symbol blocker did not recur.
- Runtime stability follow-ups:
  - focused target repro (`r88`) passed with retry masking disabled and `runs_per_test=5`:
    - `docs/s390x/logs/2026-02-25/proxy-docker-tests-r88-20260225T013342Z.log`
  - broader 4-target no-retry sweep (`r89`) passed:
    - `docs/s390x/logs/2026-02-25/proxy-docker-tests-r89-20260225T013608Z.log`
  - broader repeated-run sweep (`r90`, `runs_per_test=3`) passed:
    - `docs/s390x/logs/2026-02-25/proxy-docker-tests-r90-20260225T013754Z.log`
