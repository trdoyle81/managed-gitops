# Produce CRDs that work back to Kubernetes 1.11 (no version conversion)
CRD_OPTIONS ?= "crd:trivialVersions=true,preserveUnknownFields=false"
# ENVTEST_K8S_VERSION refers to the version of kubebuilder assets to be downloaded by envtest binary.
ENVTEST_K8S_VERSION = 1.21

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Get the OS and ARCH values to be used for building the binary.
OS ?= $(shell go env GOOS)
ARCH ?= $(shell go env GOARCH)

# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

all: build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

manifests: controller-gen ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
	$(CONTROLLER_GEN) $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases

generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

test: fmt vet envtest ## Run tests.
	KUBEBUILDER_ASSETS="$(shell $(ENVTEST) use $(ENVTEST_K8S_VERSION) -p path)" go test -timeout=2m -p=1 ./... -coverprofile cover.out -coverpkg=./... -tags skiproutes

##@ Build

build: generate fmt vet ## Build manager binary.
	CGO_ENABLED=0 GOOS=$(OS) GOARCH=$(ARCH) go build -o bin/manager main.go

run: manifests generate fmt vet ## Run a controller from your host.
	DISABLE_APPSTUDIO_WEBHOOK=true go run ./main.go --zap-log-level info --zap-time-encoding=rfc3339nano

runexec: ## Run a controller from your host using exe in current folder
ifeq (,$(wildcard ./main))
runexec: manifests generate fmt vet
	@echo Building and running backend
	CGO_ENABLED=0 GOOS=$(OS) GOARCH=$(ARCH) go build main.go
	DISABLE_APPSTUDIO_WEBHOOK=true ./main --zap-log-level info --zap-time-encoding=rfc3339nano
else
runexec:
	@echo Running backend using existing main executable.
	DISABLE_APPSTUDIO_WEBHOOK=true ./main --zap-log-level info --zap-time-encoding=rfc3339nano
endif

# more on controller log level configuration: https://sdk.operatorframework.io/docs/building-operators/golang/references/logging/

chaos-run: manifests generate fmt vet ## Chaos Engineering: Simulate a controller that restarts every ~33 seconds.
	go build -o /tmp/backend-manager-chaos  main.go
	DISABLE_APPSTUDIO_WEBHOOK=true KILL_INTERVAL="45" KILL_INITIAL="10" ../utilities/random-kill.sh /tmp/backend-manager-chaos --zap-log-level info --zap-time-encoding=rfc3339nano
	rm /tmp/backend-manager-chaos

##@ Deployment

# install: manifests kustomize ## Install CRDs into the K8s cluster specified in ~/.kube/config.
# 	$(KUSTOMIZE) build config/crd | kubectl apply -f -

# uninstall: manifests kustomize ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
# 	$(KUSTOMIZE) build config/crd | kubectl delete -f -

# deploy: manifests kustomize ## Deploy controller to the K8s cluster specified in ~/.kube/config.
# 	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
# 	$(KUSTOMIZE) build config/default | kubectl apply -f -

# undeploy: ## Undeploy controller from the K8s cluster specified in ~/.kube/config.
# 	$(KUSTOMIZE) build config/default | kubectl delete -f -

CONTROLLER_GEN = $(shell pwd)/bin/controller-gen
controller-gen: ## Download controller-gen locally if necessary.
	$(call go-get-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen@v0.6.1)

KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
	$(call go-get-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v4@v4.5.5)

GO_SEC = $(shell pwd)/bin/gosec
go_sec: ## Download gosec locally if necessary.
	$(call go-get-tool,$(GO_SEC),github.com/securego/gosec/v2/cmd/gosec@latest)


ENVTEST = $(shell pwd)/bin/setup-envtest
envtest: ## Download envtest-setup locally if necessary.
	$(call go-get-tool,$(ENVTEST),sigs.k8s.io/controller-runtime/tools/setup-envtest@latest)

# go-get-tool will 'go install' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef

# .PHONY: bundle
# bundle: manifests kustomize ## Generate bundle manifests and metadata, then validate generated files.
# 	operator-sdk generate kustomize manifests -q
# 	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
# 	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
# 	operator-sdk bundle validate ./bundle

# .PHONY: bundle-build
# bundle-build: ## Build the bundle image.
# 	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

# .PHONY: bundle-push
# bundle-push: ## Push the bundle image.
# 	$(MAKE) docker-push IMG=$(BUNDLE_IMG)

.PHONY: lint
lint:
	golangci-lint --version
	GOMAXPROCS=2 golangci-lint run --fix --verbose --timeout 300s

# .PHONY: opm
# OPM = ./bin/opm
# opm: ## Download opm locally if necessary.
# ifeq (,$(wildcard $(OPM)))
# ifeq (,$(shell which opm 2>/dev/null))
# 	@{ \
# 	set -e ;\
# 	mkdir -p $(dir $(OPM)) ;\
# 	OS=$(shell go env GOOS) && ARCH=$(shell go env GOARCH) && \
# 	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v1.15.1/$${OS}-$${ARCH}-opm ;\
# 	chmod +x $(OPM) ;\
# 	}
# else
# OPM = $(shell which opm)
# endif
# endif

# # A comma-separated list of bundle images (e.g. make catalog-build BUNDLE_IMGS=example.com/operator-bundle:v0.1.0,example.com/operator-bundle:v0.2.0).
# # These images MUST exist in a registry and be pull-able.
# BUNDLE_IMGS ?= $(BUNDLE_IMG)

# # The image tag given to the resulting catalog image (e.g. make catalog-build CATALOG_IMG=example.com/operator-catalog:v0.2.0).
# CATALOG_IMG ?= $(IMAGE_TAG_BASE)-catalog:v$(VERSION)

# # Set CATALOG_BASE_IMG to an existing catalog image tag to add $BUNDLE_IMGS to that image.
# ifneq ($(origin CATALOG_BASE_IMG), undefined)
# FROM_INDEX_OPT := --from-index $(CATALOG_BASE_IMG)
# endif

# # Build a catalog image by adding bundle images to an empty catalog using the operator package manager tool, 'opm'.
# # This recipe invokes 'opm' in 'semver' bundle add mode. For more information on add modes, see:
# # https://github.com/operator-framework/community-operators/blob/7f1438c/docs/packaging-operator.md#updating-your-existing-operator
# .PHONY: catalog-build
# catalog-build: opm ## Build a catalog image.
# 	$(OPM) index add --container-tool docker --mode semver --tag $(CATALOG_IMG) --bundles $(BUNDLE_IMGS) $(FROM_INDEX_OPT)

# # Push the catalog image.
# .PHONY: catalog-push
# catalog-push: ## Push a catalog image.
# 	$(MAKE) docker-push IMG=$(CATALOG_IMG)

.PHONY: gosec
gosec: go_sec
	$(GO_SEC) ./...


# Remove the vendor and bin folders
.PHONY: clean
clean:
	rm -rf vendor/ bin/

# Remove the vendor and bin folders
.PHONY: clean-exec
clean-exec:
	rm main
