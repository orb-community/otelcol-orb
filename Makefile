include ./Makefile.Common

RUN_CONFIG?=local/config.yaml
CMD?=
OTEL_VERSION=main
OTEL_STABLE_VERSION=main
ORB_DOCKERHUB_REPO=orbcommunity
DOCKER_IMAGE_NAME_PREFIX ?= otelcol-orb
ORB_VERSION=0.29.0
REF_TAG ?= develop

VERSION=$(shell git describe --always --match "v[0-9]*" HEAD)

COMP_REL_PATH=cmd/otelcontribcol/components.go
MOD_NAME=github.com/open-telemetry/opentelemetry-collector-contrib

GROUP ?= all
FOR_GROUP_TARGET=for-$(GROUP)-target

FIND_MOD_ARGS=-type f -name "go.mod"
TO_MOD_DIR=dirname {} \; | sort | grep -E '^./'
EX_COMPONENTS=-not -path "./receiver/*" -not -path "./processor/*" -not -path "./exporter/*" -not -path "./extension/*" -not -path "./connector/*"
EX_INTERNAL=-not -path "./internal/*"
EX_PKG=-not -path "./pkg/*"
EX_CMD=-not -path "./cmd/*"

# NONROOT_MODS includes ./* dirs (excludes . dir)
NONROOT_MODS := $(shell find . $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )

RECEIVER_MODS_0 := $(shell find ./receiver/[a-k]* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
RECEIVER_MODS_1 := $(shell find ./receiver/[l-z]* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
RECEIVER_MODS := $(RECEIVER_MODS_0) $(RECEIVER_MODS_1)
PROCESSOR_MODS := $(shell find ./processor/* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
EXPORTER_MODS := $(shell find ./exporter/* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
EXTENSION_MODS := $(shell find ./extension/* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
CONNECTOR_MODS := $(shell find ./connector/* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
INTERNAL_MODS := $(shell find ./internal/* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
PKG_MODS := $(shell find ./pkg/* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
CMD_MODS := $(shell find ./cmd/* $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) )
OTHER_MODS := $(shell find . $(EX_COMPONENTS) $(EX_INTERNAL) $(EX_PKG) $(EX_CMD) $(FIND_MOD_ARGS) -exec $(TO_MOD_DIR) ) $(PWD)
ALL_MODS := $(RECEIVER_MODS) $(PROCESSOR_MODS) $(EXPORTER_MODS) $(EXTENSION_MODS) $(CONNECTOR_MODS) $(INTERNAL_MODS) $(PKG_MODS) $(CMD_MODS) $(OTHER_MODS)

# find -exec dirname cannot be used to process multiple matching patterns
FIND_INTEGRATION_TEST_MODS={ find . -type f -name "*integration_test.go" & find . -type f -name "*e2e_test.go" -not -path "./testbed/*"; }
INTEGRATION_MODS := $(shell $(FIND_INTEGRATION_TEST_MODS) | xargs $(TO_MOD_DIR) | uniq)

ifeq ($(GOOS),windows)
	EXTENSION := .exe
endif

.DEFAULT_GOAL := all

all-modules:
	@echo $(NONROOT_MODS) | tr ' ' '\n' | sort

all-groups:
	@echo "receiver-0: $(RECEIVER_MODS_0)"
	@echo "\nreceiver-1: $(RECEIVER_MODS_1)"
	@echo "\nreceiver: $(RECEIVER_MODS)"
	@echo "\nprocessor: $(PROCESSOR_MODS)"
	@echo "\nexporter: $(EXPORTER_MODS)"
	@echo "\nextension: $(EXTENSION_MODS)"
	@echo "\nconnector: $(CONNECTOR_MODS)"
	@echo "\ninternal: $(INTERNAL_MODS)"
	@echo "\npkg: $(PKG_MODS)"
	@echo "\ncmd: $(CMD_MODS)"
	@echo "\nother: $(OTHER_MODS)"

.PHONY: all
all: install-tools all-common goporto multimod-verify gotest otelcontribcol

.PHONY: all-common
all-common:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="common"

.PHONY: e2e-test
e2e-test: otelcontribcol oteltestbedcol
	$(MAKE) -C testbed run-tests

.PHONY: integration-test
integration-test:
	@$(MAKE) for-integration-target TARGET="mod-integration-test"

.PHONY: integration-tests-with-cover
integration-tests-with-cover:
	@$(MAKE) for-integration-target TARGET="do-integration-tests-with-cover"

.PHONY: gogci
gogci:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="gci"

.PHONY: gotidy
gotidy:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="tidy"

.PHONY: gomoddownload
gomoddownload:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="moddownload"

.PHONY: gotest
gotest:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="test"

.PHONY: gotest-with-cover
gotest-with-cover:
	@$(MAKE) $(FOR_GROUP_TARGET) TARGET="test-with-cover"
	$(GOCMD) tool covdata textfmt -i=./coverage/unit -o ./$(GROUP)-coverage.txt

.PHONY: gofmt
gofmt:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="fmt"

.PHONY: golint
golint:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="lint"

.PHONY: gogovulncheck
gogovulncheck:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="govulncheck"

.PHONY: goporto
goporto: $(PORTO)
	$(PORTO) -w --include-internal --skip-dirs "^cmd$$" ./

.PHONY: for-all
for-all:
	@echo "running $${CMD} in root"
	@$${CMD}
	@set -e; for dir in $(NONROOT_MODS); do \
	  (cd "$${dir}" && \
	  	echo "running $${CMD} in $${dir}" && \
	 	$${CMD} ); \
	done

COMMIT?=HEAD
MODSET?=contrib-core
REMOTE?=git@github.com:open-telemetry/opentelemetry-collector-contrib.git
.PHONY: push-tags
push-tags: $(MULTIMOD)
	$(MULTIMOD) verify
	set -e; for tag in `$(MULTIMOD) tag -m ${MODSET} -c ${COMMIT} --print-tags | grep -v "Using" `; do \
		echo "pushing tag $${tag}"; \
		git push ${REMOTE} $${tag}; \
	done;

# Define a delegation target for each module
.PHONY: $(ALL_MODS)
$(ALL_MODS):
	@echo "Running target '$(TARGET)' in module '$@' as part of group '$(GROUP)'"
	$(MAKE) -C $@ $(TARGET)

# Trigger each module's delegation target
.PHONY: for-all-target
for-all-target: $(ALL_MODS)

.PHONY: for-receiver-target
for-receiver-target: $(RECEIVER_MODS)

.PHONY: for-receiver-0-target
for-receiver-0-target: $(RECEIVER_MODS_0)

.PHONY: for-receiver-1-target
for-receiver-1-target: $(RECEIVER_MODS_1)

.PHONY: for-processor-target
for-processor-target: $(PROCESSOR_MODS)

.PHONY: for-exporter-target
for-exporter-target: $(EXPORTER_MODS)

.PHONY: for-extension-target
for-extension-target: $(EXTENSION_MODS)

.PHONY: for-connector-target
for-connector-target: $(CONNECTOR_MODS)

.PHONY: for-internal-target
for-internal-target: $(INTERNAL_MODS)

.PHONY: for-pkg-target
for-pkg-target: $(PKG_MODS)

.PHONY: for-cmd-target
for-cmd-target: $(CMD_MODS)

.PHONY: for-other-target
for-other-target: $(OTHER_MODS)

.PHONY: for-integration-target
for-integration-target: $(INTEGRATION_MODS)

# Debugging target, which helps to quickly determine whether for-all-target is working or not.
.PHONY: all-pwd
all-pwd:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="pwd"

.PHONY: docker-component # Not intended to be used directly
docker-component: check-component
	GOOS=linux GOARCH=amd64 $(MAKE) $(COMPONENT)
	cp ./bin/$(COMPONENT)_linux_amd64 ./cmd/$(COMPONENT)/$(COMPONENT)
	docker build -t $(COMPONENT) ./cmd/$(COMPONENT)/
	rm ./cmd/$(COMPONENT)/$(COMPONENT)

.PHONY: check-component
check-component:
ifndef COMPONENT
	$(error COMPONENT variable was not defined)
endif

.PHONY: docker-otelcolagent
docker-otelcolagent:
	docker build \
	  --tag=$(ORB_DOCKERHUB_REPO)/$(DOCKER_IMAGE_NAME_PREFIX)-agent:$(REF_TAG) \
	  --tag=$(ORB_DOCKERHUB_REPO)/$(DOCKER_IMAGE_NAME_PREFIX)-agent:$(ORB_VERSION) \
	  --tag=$(ORB_DOCKERHUB_REPO)/$(DOCKER_IMAGE_NAME_PREFIX)-agent:$(ORB_VERSION)-$(COMMIT_HASH) \
	  -f cmd/otelcol-orb-agent/Dockerfile .

.PHONY: docker-otelcolmaestro
docker-otelcolmaestro:
	docker build \
	  --tag=$(ORB_DOCKERHUB_REPO)/$(DOCKER_IMAGE_NAME_PREFIX)-maestro:$(REF_TAG) \
	  --tag=$(ORB_DOCKERHUB_REPO)/$(DOCKER_IMAGE_NAME_PREFIX)-maestro:$(ORB_VERSION) \
	  --tag=$(ORB_DOCKERHUB_REPO)/$(DOCKER_IMAGE_NAME_PREFIX)-maestro:$(ORB_VERSION)-$(COMMIT_HASH) \
	  -f cmd/otelcol-orb-maestro/Dockerfile .

.PHONY: generate
generate: install-tools
	go install go.opentelemetry.io/collector/cmd/mdatagen@latest
	$(MAKE) for-all CMD="mdatagen generate ./..."

FILENAME?=$(shell git branch --show-current)

.PHONY: genotelcolagent
genotelcolagent: $(BUILDER)
	$(BUILDER) --skip-compilation --config cmd/otelcol-orb-agent/builder-config.yaml --output-path cmd/otelcol-orb-agent
	$(MAKE) -C cmd/otelcol-orb-agent fmt

.PHONY: genotelcolmaestro
genotelcolmaestro: $(BUILDER)
	$(BUILDER) --skip-compilation --config cmd/otelcol-orb-maestro/builder-config.yaml --output-path cmd/otelcol-orb-maestro
	$(MAKE) -C cmd/otelcol-orb-maestro fmt

# Build the Collector executable.
.PHONY: otelcolagent
otelcolmaestro:
	cd ./cmd/otelcol-orb-agent && GO111MODULE=on CGO_ENABLED=0 $(GOCMD) build -trimpath -o ../../bin/otelcontribcol_$(GOOS)_$(GOARCH)$(EXTENSION) \
		-tags $(GO_BUILD_TAGS) .

# Build the Collector executable.
.PHONY: otelcolmaestro
otelcolmaestro:
	cd ./cmd/otelcol-orb-maestro && GO111MODULE=on CGO_ENABLED=0 $(GOCMD) build -trimpath -o ../../bin/otelcontribcol_$(GOOS)_$(GOARCH)$(EXTENSION) \
		-tags $(GO_BUILD_TAGS) .

# Verify existence of metadata.yaml for components specified as default components in the collector.
.PHONY: checkmetadata
checkmetadata: $(CHECKFILE)
	$(CHECKFILE) --project-path $(CURDIR) --component-rel-path $(COMP_REL_PATH) --module-name $(MOD_NAME) --file-name "metadata.yaml"

.PHONY: checkapi
checkapi:
	$(GOCMD) run cmd/checkapi/main.go .

.PHONY: all-checklinks
all-checklinks:
	$(MAKE) $(FOR_GROUP_TARGET) TARGET="checklinks"
