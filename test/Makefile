# Copyright Authors of Cilium
# SPDX-License-Identifier: Apache-2.0

include ../Makefile.defs

# Determines if the eBPF unit tests are ran with `sudo`
RUN_WITH_SUDO ?= true
ifeq ($(RUN_WITH_SUDO), true)
	RUN_WITH_SUDO=-exec sudo
else
	RUN_WITH_SUDO=
endif

HOLD_ENVIRONMENT ?= true

TEST_ARTIFACTS = ./tmp.yaml ./*_service_manifest.json ./*_manifest.yaml
TEST_ARTIFACTS += ./*_policy.json ./k8s-*.xml ./runtime.xml ./test_results
TEST_ARTIFACTS += ./test.test

NETNEXT ?= false
KUBEPROXY ?= 1
NO_CILIUM_ON_NODES ?= ""

GINKGO = $(QUIET) ginkgo

REGISTRY_CREDENTIALS ?= "${DOCKER_LOGIN}:${DOCKER_PASSWORD}"

.PHONY: all build build-darwin test k8s-kind s390x-deploy s390x-smoke s390x-policy s390x-bpf-subset s390x-collect s390x-harness s390x-integration-wide clean

all: build

build:
	@$(ECHO_GINKGO)$@
	$(GINKGO) build

build-darwin:
	@$(ECHO_GINKGO)$@
	GOOS=darwin $(GINKGO) build

test:
	@echo "Running the legacy tests via the make target is no longer supported."
	@echo ""
	@echo "For now, use the following guide to invoke these tests:"
	@echo "https://docs.cilium.io/en/latest/contributing/testing/e2e_legacy/#running-locally-ginkgo-tests-based-on-ginkgo-s-github-workflow"

# Match kind-image target in parent directory
k8s-kind: export DOCKER_REGISTRY=localhost:5000
k8s-kind:
	@if [ -z "$(FOCUS)" ]; then \
		>&2 echo "usage: FOCUS=K8sFoo make k8s-kind"; \
		exit 1; \
	fi
	@CNI_INTEGRATION=kind \
		K8S_VERSION="$$(kubectl version -o json | jq -r '.serverVersion | "\(.major).\(.minor)"')" \
		NETNEXT="$(NETNEXT)" \
		KUBEPROXY="$(KUBEPROXY)" \
		NO_CILIUM_ON_NODES="$(NO_CILIUM_ON_NODES)" \
		INTEGRATION_TESTS=true ginkgo --focus "$(FOCUS)" -v -- \
			-cilium.testScope=k8s \
			-cilium.kubeconfig=$$(echo ~/.kube/config) \
			-cilium.passCLIEnvironment=true \
			-cilium.image="$(DOCKER_REGISTRY)/cilium/cilium-dev" \
			-cilium.tag="local" \
			-cilium.operator-image="quay.io/cilium/operator" \
			-cilium.operator-suffix="-ci" \
			-cilium.holdEnvironment=$(HOLD_ENVIRONMENT)

s390x-deploy:
	./s390x/deploy_cilium_s390x.sh

s390x-smoke:
	./s390x/smoke_status.sh

s390x-policy:
	./s390x/policy_integration.sh

s390x-bpf-subset:
	./s390x/bpf_regression_subset.sh

s390x-collect:
	./s390x/collect_artifacts.sh

s390x-harness:
	./s390x/run_harness.sh

s390x-integration-wide:
	./s390x/integration_wide.sh

clean:
	@$(ECHO_CLEAN)
	-$(QUIET) rm -rf $(TEST_ARTIFACTS)
