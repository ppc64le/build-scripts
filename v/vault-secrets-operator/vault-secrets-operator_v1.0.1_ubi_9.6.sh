#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vault-secrets-operator
# Version       : v1.0.1
# Source repo   : https://github.com/hashicorp/vault-secrets-operator.git
# Tested on     : UBI 9.6 (ppc64le)
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
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="vault-secrets-operator"
PACKAGE_URL=https://github.com/hashicorp/${PACKAGE_NAME}.git
PACKAGE_VERSION=${1:-v1.0.1}
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")

ARCH="ppc64le"
GOOS="linux"
GOARCH="ppc64le"

# Versions
GO_VERSION=1.25.2
KUBERNETES_VERSION="v1.34.1"
KUBECTL_VERSION="v1.34.1"
KIND_VERSION="v0.30.0"
KUSTOMIZE_VERSION="v5.7.1"
TERRAFORM_VERSION="v1.13.3"

# KIND / Vault cluster settings
KIND_CLUSTER_NAME="vault-secrets-operator"
NAMESPACE="vault-operator"
VAULT_NAMESPACE="vault"

# ----------------------------------------------------------------------------- 
# Step 1. Install System deps
# -----------------------------------------------------------------------------
dnf install -y git wget tar gcc make unzip which findutils rsync openssl file tzdata sudo procps-ng podman

# ----------------------------------------------------------------------------- 
# Step 2. Install Go
# -----------------------------------------------------------------------------
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH
go version

# ----------------------------------------------------------------------------- 
# Step 3. Install Helm
# -----------------------------------------------------------------------------
HELM_VERSION="v3.15.4"
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-ppc64le.tar.gz
tar -zxvf helm-${HELM_VERSION}-linux-ppc64le.tar.gz
mv linux-ppc64le/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
helm version

# ----------------------------------------------------------------------------- 
# Step 5. Install kubectl, kustomize
# -----------------------------------------------------------------------------
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/ppc64le/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/
kubectl version --client

KUSTOMIZE_TAR="kustomize_${KUSTOMIZE_VERSION}_linux_ppc64le.tar.gz"
KUSTOMIZE_URL="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/${KUSTOMIZE_TAR}"
curl -sLO "$KUSTOMIZE_URL" && tar -xzf "$KUSTOMIZE_TAR"
chmod +x kustomize && mv kustomize /usr/local/bin/
kustomize version

# ----------------------------------------------------------------------------- 
# Step 6. Clone source
# -----------------------------------------------------------------------------
cd "$BUILD_HOME"
git clone "$PACKAGE_URL" && cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"
export VAULT_DIR="$(pwd)"

# ----------------------------------------------------------------------------- 
# Step 7. Build
# -----------------------------------------------------------------------------
ret=0
go mod download all && go mod tidy
CGO_ENABLED=1 make ci-build BUILD_DIR="$VAULT_DIR" GOOS="$GOOS" GOARCH="$GOARCH" VERSION="$PACKAGE_VERSION" || ret=$?

if [ "$ret" -ne 0 ]; then
  echo "ERROR: $PACKAGE_NAME-$PACKAGE_VERSION build failed."
  exit 1
else
  VERSION=$(./linux/ppc64le/vault-secrets-operator -version | grep -o 'GitVersion:"[^"]*"' | cut -d'"' -f2)
  echo "vault-secrets-operator built; version output: ${VERSION}"
fi

# ----------------------------------------------------------------------------- 
# Step 8. Unit Test
# -----------------------------------------------------------------------------
export VAULT_DIR="$(pwd)"
export PATH="${VAULT_DIR}/bin:$PATH"

# create user
useradd -m -s /bin/bash tester || true
groupadd podman || true
usermod -aG podman tester || true
chown -R tester:tester "$VAULT_DIR" || true

su - tester -c "
set -x
cd ${VAULT_DIR}
export PATH=\$PATH:/usr/local/go/bin
echo 'Running unit tests...'
ret=0
make ci-test || ret=\$?
if [ \$ret -ne 0 ]; then
  echo \"ERROR: ${PACKAGE_NAME}-${PACKAGE_VERSION} unit-test failed.\"
  exit 2
else
  echo \"${PACKAGE_NAME}-${PACKAGE_VERSION} unit-test Passed.\"
fi
"
