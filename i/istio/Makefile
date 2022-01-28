# Based on https://github.com/querycap/istio/blob/release-1.11/Makefile

# all need run on ppc64le host
VERSION ?= 1.12.0
HUB ?= docker.io/istio
TEMP_ROOT ?= $(CWD)/.tmp
ISTIO_REPO = https://github.com/istio/istio.git
ISTIO_PROXY_REPO = https://github.com/istio/proxy.git
ISTIO_TOOLS_REPO = https://github.com/istio/tools.git
PUBLISH_IMAGES ?= no
PULL_TOOLS ?= yes

# version tag or branch
# examples: make xxx TAG=1.11.0
TAG = $(VERSION)
RELEASE_BRANCH = master

GIT_CLONE = git clone
GIT_CLONE_TOOLS = git clone

ifneq ($(TAG),master)
	RELEASE_BRANCH = release-$(word 1,$(subst ., ,$(VERSION))).$(word 2,$(subst ., ,$(VERSION)))
	GIT_CLONE = git clone -b $(TAG)
	GIT_CLONE_TOOLS = git clone -b $(RELEASE_BRANCH)
endif

PUBLISH_OPT =
DOCKERX_PUSH = false
ifeq ($(PUBLISH_IMAGES),yes)
  PUBLISH_OPT = --push
  DOCKERX_PUSH = true
endif

BUILD_TOOLS_VERSION = $(RELEASE_BRANCH)-latest
BUILD_TOOLS_IMAGE = $(HUB)/build-tools:$(BUILD_TOOLS_VERSION)
BUILD_TOOLS_PROXY_IMAGE = $(HUB)/build-tools-proxy:$(BUILD_TOOLS_VERSION)

echo:
	@echo "TAG: $(TAG)"
	@echo "RELEASE_BRANCH: $(RELEASE_BRANCH)"

clean.build-tools:
	rm -rf $(TEMP_ROOT)/tools

clone.build-tools:
	$(GIT_CLONE_TOOLS) --depth=1 $(ISTIO_TOOLS_REPO) $(TEMP_ROOT)/tools
	patches/apply_patches.sh $(TEMP_ROOT)/tools tools ${BUILD_TOOLS_VERSION}

# Build build-tools && build-tools-proxy for ppc64le
dockerx.build-tools: clean.build-tools clone.build-tools
	cd $(TEMP_ROOT)/tools/docker/build-tools \
	    && DRY_RUN=1 HUB=$(HUB) CONTAINER_BUILDER="buildx build $(PUBLISH_OPT) --platform=linux/ppc64le" ./build-and-push.sh; \

cleanup.envoy:
	rm -rf $(TEMP_ROOT)/proxy

ISTIO_ENVOY_VERSION = $(shell cat $(TEMP_ROOT)/istio/istio.deps | grep lastStableSHA | sed 's/.*"lastStableSHA": "\([a-zA-Z0-9]*\)"/\1/g')

# Clone istio/proxy
# To checkout last stable sha from istio/istio
clone.envoy: cleanup.istio clone.istio
	git clone $(ISTIO_PROXY_REPO) $(TEMP_ROOT)/proxy
	cd $(TEMP_ROOT)/proxy && git checkout $(ISTIO_ENVOY_VERSION)
	patches/apply_patches.sh $(TEMP_ROOT)/proxy proxy ${ISTIO_ENVOY_VERSION}

# Build envoy
build.envoy: cleanup.envoy clone.envoy
	if [ '$(PULL_TOOLS)' = 'yes' ]; then docker pull $(BUILD_TOOLS_PROXY_IMAGE); fi
	cd $(TEMP_ROOT)/proxy && make BUILD_WITH_CONTAINER=1 IMG=$(BUILD_TOOLS_PROXY_IMAGE) build_envoy
	mkdir -p $(TEMP_ROOT)/envoy-linux-ppc64le && cp $(TEMP_ROOT)/proxy/bazel-bin/src/envoy/envoy $(TEMP_ROOT)/envoy-linux-ppc64le/envoy

cleanup.istio:
	rm -rf $(TEMP_ROOT)/istio

clone.istio:
	$(GIT_CLONE) --depth=1 $(ISTIO_REPO) $(TEMP_ROOT)/istio
	patches/apply_patches.sh $(TEMP_ROOT)/istio istio ${VERSION}

ISTIO_MAKE = cd $(TEMP_ROOT)/istio && IMG=$(BUILD_TOOLS_IMAGE) HUB=$(HUB) VERSION=$(VERSION) BASE_VERSION=$(TAG) TAG=$(TAG) make

ISTIO_LINUX_PPC64LE_RELEASE_DIR = $(TEMP_ROOT)/istio/out/linux_ppc64le/release

## avoid to download from google storage
## envoy-centos-$(ISTIO_ENVOY_VERSION) just a hack
copy.envoy: copy.envoy-ppc64le copy.wasm

copy.wasm:
	for f in $(TEMP_ROOT)/envoy-linux-ppc64le/extensions/*.wasm; do \
  		filename=$$(basename $${f}); \
  		cp $${f} "$(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/$${filename}"; \
		cp $${f} "$(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/$$(echo $${filename} | sed "s/-/_/g" | sed "s/_filter/-$(ISTIO_ENVOY_VERSION)/")"; \
  		cp $${f} "$(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/$${filename}"; \
		cp $${f} "$(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/$$(echo $${filename} | sed "s/-/_/g" | sed "s/_filter/-$(ISTIO_ENVOY_VERSION)/")"; \
	done

copy.envoy-ppc64le:
	rm -rf $(ISTIO_LINUX_PPC64LE_RELEASE_DIR) && mkdir -p $(ISTIO_LINUX_PPC64LE_RELEASE_DIR)
	cp $(TEMP_ROOT)/envoy-linux-ppc64le/envoy $(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/envoy
	cp $(TEMP_ROOT)/envoy-linux-ppc64le/envoy $(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/envoy-$(ISTIO_ENVOY_VERSION)
	cp $(TEMP_ROOT)/envoy-linux-ppc64le/envoy $(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/envoy-centos-$(ISTIO_ENVOY_VERSION)

# Build istio binaries and copy envoy binary for ppc64le
# in github actions it will download from artifacts
build.istio: cleanup.istio clone.istio copy.envoy
	cd $(TEMP_ROOT)/istio \
		&& $(ISTIO_MAKE) build-linux TARGET_ARCH=ppc64le

ESCAPED_HUB := $(shell echo $(HUB) | sed "s/\//\\\\\//g")

# Replace istio base images and pull latest BUILD_TOOLS_IMAGE
# sed must be gnu sed
dockerx.istio.prepare:
	sed -i -e 's/gcr.io\/istio-release\/\(base\|distroless\)/$(ESCAPED_HUB)\/\1/g' $(TEMP_ROOT)/istio/pilot/docker/Dockerfile.pilot
	sed -i -e 's/gcr.io\/istio-release\/\(base\|distroless\)/$(ESCAPED_HUB)\/\1/g' $(TEMP_ROOT)/istio/pilot/docker/Dockerfile.proxyv2
	sed -i -e 's/gcr.io\/istio-release\/\(base\|distroless\)/$(ESCAPED_HUB)\/\1/g' $(TEMP_ROOT)/istio/operator/docker/Dockerfile.operator
	sed -i -e 's/gcr.io\/istio-release\/\(base\|distroless\)/$(ESCAPED_HUB)\/\1/g' $(TEMP_ROOT)/istio/cni/deployments/kubernetes/Dockerfile.install-cni
	if [ '$(PULL_TOOLS)' == 'yes' ]; then docker pull $(BUILD_TOOLS_IMAGE); fi

# Build istio base images
dockerx.istio-base:
	$(ISTIO_MAKE) dockerx.base DOCKERX_PUSH=$(DOCKERX_PUSH) DOCKER_ARCHITECTURES=linux/ppc64le
	$(ISTIO_MAKE) dockerx.distroless DOCKERX_PUSH=$(DOCKERX_PUSH) DOCKER_ARCHITECTURES=linux/ppc64le

COMPONENTS = proxyv2 pilot operator install-cni
dockerx.istio-images: dockerx.istio.prepare dockerx.istio-base
	$(foreach component,$(COMPONENTS),cd $(TEMP_ROOT)/istio && $(ISTIO_MAKE) dockerx.$(component) DOCKERX_PUSH=$(DOCKERX_PUSH) DOCKER_BUILD_VARIANTS="default distroless" DOCKER_ARCHITECTURES=linux/ppc64le;)

# Build istio deb
deb:
	$(ISTIO_MAKE) deb TARGET_ARCH=ppc64le
	mkdir -p $(TEMP_ROOT)/deb
	cp $(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/istio-sidecar.deb $(TEMP_ROOT)/istio-sidecar.deb
	cp $(ISTIO_LINUX_PPC64LE_RELEASE_DIR)/istio.deb $(TEMP_ROOT)/istio.deb

check.istio:
	@echo "ISTIO_ENVOY_VERSION: $(ISTIO_ENVOY_VERSION)"
	docker pull --platform=linux/ppc64le $(HUB)/proxyv2:$(VERSION)-distroless
	docker run --rm --platform=linux/ppc64le --entrypoint=/usr/local/bin/envoy $(HUB)/proxyv2:$(VERSION)-distroless --version
