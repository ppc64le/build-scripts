#!/bin/bash -ex
# -----------------------------------------------------------------------------
# Package       : flux2
# Version       : v0.38.3
# Source repo   : https://github.com/fluxcd/flux2.git
# Tested on     : UBI 9.3
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

PACKAGE_NAME="flux2"
PACKAGE_VERSION="${1:-v0.38.3}"
VERSION="${PACKAGE_VERSION#v}"
PACKAGE_URL="https://github.com/fluxcd/${PACKAGE_NAME}"
BUILD_HOME="$(pwd)"
GO_VERSION="1.24.4"
KUSTOMIZE_VERSION="v5.3.0"
KIND_VERSION="v0.17.0"
KINDEST_NODE_VERSION="v1.25.3"
KUBERNETES_VERSION="v1.31.0"
ARCH="ppc64le"
SCRIPT_PATH=$(dirname $(realpath $0))

# Install dependencies
yum install -y yum-utils git gcc wget tar make rsync which unzip jq sudo procps-ng iptables-nft

# Install Go
GO_TAR="go${GO_VERSION}.linux-ppc64le.tar.gz"
wget "https://golang.org/dl/${GO_TAR}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "${GO_TAR}"
rm -f "${GO_TAR}"
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# Install Docker
yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Start Docker daemon safely
(dockerd > /tmp/dockerd.log 2>&1) &
# Wait for Docker to be ready, or exit with error if not
timeout 30 bash -c 'until docker info >/dev/null 2>&1; do sleep 1; done' || {
    echo "ERROR: Docker failed to start"
    cat /tmp/dockerd.log
    exit 1
}
echo "Docker is up and running"

# Install kubectl
curl -LO "https://dl.k8s.io/release/${KINDEST_NODE_VERSION}/bin/linux/ppc64le/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/
kubectl version

# Install kind
curl -Lo kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-ppc64le
chmod +x kind && mv kind /usr/local/bin/
kind version

# Install kustomize
curl -sLO "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_ppc64le.tar.gz"
tar -xzf "kustomize_${KUSTOMIZE_VERSION}_linux_ppc64le.tar.gz"
chmod +x kustomize && mv kustomize /usr/local/bin/
kustomize version

# Clone flux2
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# Build flux2 repo
ret=0
make build VERSION="${VERSION}" || ret=$?
if [ "$ret" -ne 0 ] ; then
    echo "ERROR: $PACKAGE_NAME-$PACKAGE_VERSION - Build failed"
    exit 1
fi
echo "SUCCESS: $PACKAGE_NAME-$PACKAGE_VERSION build successful"

# Setup envtest
export FLUX2_DIR="$(pwd)"
export PATH="${FLUX2_DIR}/bin:$PATH"
TESTBIN_DIR="${FLUX2_DIR}/testbin/k8s/${KUBERNETES_VERSION}-linux-${ARCH}"
mkdir -p "${TESTBIN_DIR}"

# Build Kubernetes components
cd /opt
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes
git checkout "${KUBERNETES_VERSION}"
make WHAT=cmd/kube-apiserver
make WHAT=cmd/kube-controller-manager
make WHAT=cmd/kube-scheduler
cp _output/bin/kube-* "${TESTBIN_DIR}/"

# Build etcd
cd /opt
git clone https://github.com/etcd-io/etcd.git
cd etcd
git checkout v3.5.14
./build.sh
cp bin/etcd "${TESTBIN_DIR}/"

# Setup envtest tool
cd "${FLUX2_DIR}"
go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
cp "$GOPATH/bin/setup-envtest" "${FLUX2_DIR}/bin/"
/flux2/bin/setup-envtest use 1.31.0 --arch=ppc64le --bin-dir=/flux2/testbin
export KUBEBUILDER_ASSETS="${TESTBIN_DIR}"

# Run unit tests
cd "${FLUX2_DIR}"
ret=0
make test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME-$PACKAGE_VERSION Unit tests failed."
    exit 2
fi

# Build kind node image
mkdir -p "$GOPATH/src/k8s.io"
cd "$GOPATH/src/k8s.io"
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
git checkout "${KINDEST_NODE_VERSION}"
kind build node-image .
docker tag kindest/node:latest kindest/node:${KINDEST_NODE_VERSION}

# Create kind cluster
TEST_KUBECONFIG="/tmp/flux-e2e-test-kubeconfig"
kind delete cluster --name flux-e2e || true
kind create cluster --name flux-e2e --image=kindest/node:${KINDEST_NODE_VERSION} --kubeconfig "${TEST_KUBECONFIG}"
chmod 644 "${TEST_KUBECONFIG}"
export TEST_KUBECONFIG="${TEST_KUBECONFIG}"

# Build Helm Controller
cd "${FLUX2_DIR}"
git clone --depth 1 --branch "v0.28.1" https://github.com/fluxcd/helm-controller.git
cd helm-controller
sed -i 's|BUILD_PLATFORMS ?= linux/amd64|BUILD_PLATFORMS ?= linux/ppc64le|' Makefile
sed -i 's|ENVTEST_ARCH ?= amd64|ENVTEST_ARCH ?= ppc64le|' Makefile
make docker-build

# Build Source Controller
cd "${FLUX2_DIR}"
git clone --depth 1 --branch "v0.33.0" https://github.com/fluxcd/source-controller.git
cd source-controller
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}_source-controller.patch
make docker-build BUILD_ARGS="--build-arg CGO_LDFLAGS='-fuse-ld=lld' --build-arg GO_BUILD_TAGS='netgo,osusergo'"

# Build Kustomize Controller
cd "${FLUX2_DIR}"
git clone --depth 1 --branch "v0.32.0" https://github.com/fluxcd/kustomize-controller.git
cd kustomize-controller
sed -i 's|^BUILD_PLATFORMS ?= linux/amd64|BUILD_PLATFORMS ?= linux/ppc64le|' Makefile
make docker-build

# Build Notification Controller
cd "${FLUX2_DIR}"
git clone --depth 1 --branch "v0.30.2" https://github.com/fluxcd/notification-controller.git
cd notification-controller
sed -i 's|BUILD_PLATFORMS ?= linux/amd64|BUILD_PLATFORMS ?= linux/ppc64le|' Makefile
sed -i 's|ENVTEST_ARCH ?= amd64|ENVTEST_ARCH ?= ppc64le|' Makefile
make docker-build

# Build Image Reflector Controller
cd "${FLUX2_DIR}"
git clone --depth 1 --branch "v0.23.1" https://github.com/fluxcd/image-reflector-controller.git
cd image-reflector-controller
sed -i 's|BUILD_PLATFORMS ?= linux/amd64|BUILD_PLATFORMS ?= linux/ppc64le|' Makefile
sed -i 's|ENVTEST_ARCH ?= amd64|ENVTEST_ARCH ?= ppc64le|' Makefile
make docker-build

# Build Image Automation Controller
cd "${FLUX2_DIR}"
git clone --depth 1 --branch "v0.28.0" https://github.com/fluxcd/image-automation-controller.git
cd image-automation-controller
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}_source-controller.patch
make docker-build BUILD_ARGS="--build-arg CGO_LDFLAGS='-fuse-ld=lld' --build-arg GO_BUILD_TAGS='netgo,osusergo'"

# Tag and load all controller images to kind
docker tag fluxcd/source-controller:latest ghcr.io/fluxcd/source-controller:v0.33.0
docker tag fluxcd/image-automation-controller:latest ghcr.io/fluxcd/image-automation-controller:v0.28.0
docker tag fluxcd/image-reflector-controller:latest ghcr.io/fluxcd/image-reflector-controller:v0.23.1
docker tag fluxcd/notification-controller:latest ghcr.io/fluxcd/notification-controller:v0.30.2
docker tag fluxcd/helm-controller:latest ghcr.io/fluxcd/helm-controller:v0.28.1
docker tag fluxcd/kustomize-controller:latest ghcr.io/fluxcd/kustomize-controller:v0.32.0

kind load docker-image ghcr.io/fluxcd/helm-controller:v0.28.1 --name flux-e2e
kind load docker-image ghcr.io/fluxcd/image-automation-controller:v0.28.0 --name flux-e2e
kind load docker-image ghcr.io/fluxcd/image-reflector-controller:v0.23.1 --name flux-e2e
kind load docker-image ghcr.io/fluxcd/kustomize-controller:v0.32.0 --name flux-e2e
kind load docker-image ghcr.io/fluxcd/notification-controller:v0.30.2 --name flux-e2e
kind load docker-image ghcr.io/fluxcd/source-controller:v0.33.0 --name flux-e2e

# Install Flux
kind export kubeconfig --name flux-e2e
flux install --namespace=flux-system

# Run E2E tests
cd "${FLUX2_DIR}"
ret=0
make e2e || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME-$PACKAGE_VERSION E2E tests failed."
    exit 2
fi

echo "Build, unit test, and e2e tests are completed successfully for $PACKAGE_NAME-$PACKAGE_VERSION on ${ARCH}"
