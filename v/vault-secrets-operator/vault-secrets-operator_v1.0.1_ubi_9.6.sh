#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vault-secrets-operator
# Version       : v1.0.1
# Source repo   : https://github.com/hashicorp/vault-secrets-operator.git
# Tested on     : UBI 9.6
# Language      : Go
# Ci-Check  : True
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

# ----------------------------------------------------------------------------- 
# Set Variables.
# -----------------------------------------------------------------------------
PACKAGE_NAME="vault-secrets-operator"
PACKAGE_URL=https://github.com/hashicorp/${PACKAGE_NAME}.git
PACKAGE_VERSION=${1:-v1.0.1}
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
ulimit -n 65535
ARCH="ppc64le"
GOOS="linux"
GOARCH="ppc64le"

# Versions
GO_VERSION=1.25.1
KUBERNETES_VERSION="v1.31.0"
KUBECTL_VERSION="v1.31.0"
KIND_VERSION="v0.29.0"
KUSTOMIZE_VERSION="v5.0.3"
TERRAFORM_VERSION="v1.13.0"

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
# Step 4. Install kubectl, kustomize
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
# Step 5. Clone source
# -----------------------------------------------------------------------------
cd "$BUILD_HOME"
git clone "$PACKAGE_URL" && cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"
export VAULT_DIR="$(pwd)"

# ----------------------------------------------------------------------------- 
# Step 6. Build
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
# Step 7. Unit Test
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

# Note: The following steps are commented out as the integration tests are being skipped.
# They are intended as reference or guidance only — the actual steps may vary during testing.

# ----------------------------------------------------------------------------- 
# Step 8. Build Docker image for target arch - ppc64le
# -----------------------------------------------------------------------------
#OP_IMAGE="hashicorp/${PACKAGE_NAME}:${PACKAGE_VERSION}"
#OP_IMAGE_LOAD="docker.io/hashicorp/${PACKAGE_NAME}:0.0.0-dev"
#podman build  -t "${OP_IMAGE}" -t "${OP_IMAGE_LOAD}" --build-arg LD_FLAGS="" --platform "${GOOS}/${GOARCH}" .
#podman inspect "${OP_IMAGE_LOAD}" | grep -i Architecture || true
#
## ----------------------------------------------------------------------------- 
## Step 9. Setup envtest & K8 components 
## -----------------------------------------------------------------------------
#export TESTBIN_DIR="${VAULT_DIR}/testbin/k8s/${KUBERNETES_VERSION}-linux-${ARCH}"
#mkdir -p "${TESTBIN_DIR}"
#
#cd /opt && rm -rf kubernetes
#git clone https://github.com/kubernetes/kubernetes.git
#cd kubernetes
#git checkout "${KUBERNETES_VERSION}"
#
#make WHAT=cmd/kube-apiserver
#make WHAT=cmd/kube-controller-manager
#make WHAT=cmd/kube-scheduler
#cp _output/bin/kube-* "${TESTBIN_DIR}/"
#
#cd /opt
#rm -rf etcd
#git clone https://github.com/etcd-io/etcd.git
#cd etcd
#git checkout v3.5.14 && ./build.sh
#cp bin/etcd "${TESTBIN_DIR}/"
#
#cd "${VAULT_DIR}"
#export GOBIN="${VAULT_DIR}/bin"
#mkdir -p "$GOBIN"
#go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
#cp "${GOBIN}/setup-envtest" "${TESTBIN_DIR}/"
#cp ./linux/ppc64le/vault-secrets-operator ./bin/vault-secrets-operator
#
#export KUBEBUILDER_ASSETS="${TESTBIN_DIR}"
#export PATH="${TESTBIN_DIR}:$PATH"
#
## ----------------------------------------------------------------------------- 
## Step 10. Install Terraform providers
## -----------------------------------------------------------------------------
#cd /opt && rm -rf terraform
#git clone https://github.com/hashicorp/terraform.git
#cd terraform && git checkout v1.13.1 || true
#GOOS=linux GOARCH=ppc64le go build -o terraform .
#mv terraform /usr/local/bin/
#chmod +x /usr/local/bin/terraform
#terraform version
#
#export PLUGIN_BASE="/root/.terraform.d/plugins/registry.terraform.io/hashicorp"
## Create provider directories
#mkdir -p "$PLUGIN_BASE/kubernetes/2.30.0/linux_ppc64le"
#mkdir -p "$PLUGIN_BASE/kubernetes/2.29.0/linux_ppc64le"
#mkdir -p "$PLUGIN_BASE/helm/2.16.1/linux_ppc64le"
#mkdir -p "$PLUGIN_BASE/vault/4.2.0/linux_ppc64le"
#mkdir -p "$PLUGIN_BASE/random/3.4.0/linux_ppc64le"
#mkdir -p "$PLUGIN_BASE/null/3.2.1/linux_ppc64le"
# 
## Install kubernetes provider - we need 2 versions for tests.
##2.30.0
#cd /opt  && rm -rf terraform-provider-kubernetes
#git clone https://github.com/hashicorp/terraform-provider-kubernetes.git
#cd terraform-provider-kubernetes
#git checkout v2.30.0
#GOOS=linux GOARCH=ppc64le go build -o terraform-provider-kubernetes
#mv terraform-provider-kubernetes "$PLUGIN_BASE/kubernetes/2.30.0/linux_ppc64le/"
#
##2.39.0
#cd /opt && cd terraform-provider-kubernetes
#git checkout v2.29.0
#GOOS=linux GOARCH=ppc64le go build -o terraform-provider-kubernetes
#mv terraform-provider-kubernetes "$PLUGIN_BASE/kubernetes/2.29.0/linux_ppc64le/"
#
## helm provider
#cd /opt && rm -rf terraform-provider-helm
#git clone https://github.com/hashicorp/terraform-provider-helm.git
#cd terraform-provider-helm
#git checkout v2.16.1
#GOOS=linux GOARCH=ppc64le go build -o terraform-provider-helm
#mv terraform-provider-helm "$PLUGIN_BASE/helm/2.16.1/linux_ppc64le/"
# 
## vault provider
#cd /opt && rm -rf terraform-provider-vault
#git clone https://github.com/hashicorp/terraform-provider-vault.git
#cd terraform-provider-vault
#git checkout v4.2.0
#GOOS=linux GOARCH=ppc64le go build -o terraform-provider-vault
#mv terraform-provider-vault "$PLUGIN_BASE/vault/4.2.0/linux_ppc64le/"
# 
## random provider
#cd /opt && rm -rf terraform-provider-random
#git clone https://github.com/hashicorp/terraform-provider-random.git
#cd terraform-provider-random
#git checkout v3.4.0
#GOOS=linux GOARCH=ppc64le go build -o terraform-provider-random
#mv terraform-provider-random "$PLUGIN_BASE/random/3.4.0/linux_ppc64le/"
#
## null provider
#cd /opt && rm -rf terraform-provider-null
#git clone https://github.com/hashicorp/terraform-provider-null.git
#cd terraform-provider-null
#git checkout v3.2.1
#GOOS=linux GOARCH=ppc64le go build -o terraform-provider-null
#mv terraform-provider-null "$PLUGIN_BASE/null/3.2.1/linux_ppc64le/"	
#
##ensures Terraform uses the locally built providers
#export HELM_BIN="$(command -v helm)"
#export TERRAFORM_BIN="$(command -v terraform)"
#export TF_CLI_ARGS_init="-plugin-dir='/root/.terraform.d/plugins'"
#
#cat <<EOF > /root/.terraformrc
#provider_installation {
#  filesystem_mirror {
#    path    = "/root/.terraform.d/plugins"
#    include = ["*/*"]
#  }
#  direct {
#    exclude = ["*/*"]
#  }
#}
#EOF
#export TF_CLI_CONFIG_FILE=/root/.terraformrc
#
# ----------------------------------------------------------------------------- 
# Step 11. create KIND cluster using Podman and load required images.
# -----------------------------------------------------------------------------
#export KIND_EXPERIMENTAL_PROVIDER="podman"
#export KIND_IMAGE="quay.io/powercloud/kind-node:v1.33.1"
#export KIND_EXPERIMENTAL_PODMAN_NETWORK="kind-net"
#podman network create kind-net --subnet 192.168.251.0/24
#
##podman network ls
##podman network inspect kind-net
#
#mkdir -p dev-cache
#GOBIN=$(pwd)/dev-cache/ go install sigs.k8s.io/kind@v0.29.0
#chmod +x ./dev-cache/kind
#mv ./dev-cache/kind /usr/local/bin/kind
#kind --version
#
## Generate hack/kind-cluster-config.yaml if does not exists
#cd $VAULT_DIR
#KIND_CLUSTER_CONFIG_PATH="hack/kind-cluster-config.yaml"
#cat <<'EOF' > "$KIND_CLUSTER_CONFIG_PATH"
## KIND cluster config for Podman (Power environment)
#kind: Cluster
#apiVersion: kind.x-k8s.io/v1alpha4
#networking:
#  podSubnet: "10.250.0.0/16"
#  serviceSubnet: "10.251.0.0/16"
#featureGates:
#  DynamicResourceAllocation: true
#containerdConfigPatches:
#- |-
#  [plugins."io.containerd.grpc.v1.cri"]
#    enable_cdi = true
#nodes:
#- role: control-plane
#  kubeadmConfigPatches:
#  - |
#    kind: ClusterConfiguration
#    apiServer:
#        extraArgs:
#          runtime-config: "resource.k8s.io/v1beta1=true"
#    scheduler:
#        extraArgs:
#          v: "1"
#    controllerManager:
#        extraArgs:
#          v: "1"
#  - |
#    kind: InitConfiguration
#    nodeRegistration:
#      kubeletExtraArgs:
#        v: "1"
#
#EOF
#
#create kind cluster
#kind delete cluster --name "${KIND_CLUSTER_NAME}" || true
#kind create cluster --name "${KIND_CLUSTER_NAME}" --image "${KIND_IMAGE}" --config "${KIND_CLUSTER_CONFIG_PATH}" --wait 2m 
#
#Note: If Podman throws the following error:
#failed to ensure podman network: exhausted attempts trying to find a non-overlapping network,
#switch to Docker instead. Unset the KIND_EXPERIMENTAL_PROVIDER environment variable and then retry creating the cluster.
#
## Setup kubeconfig
#mkdir -p /root/.kube
#export TEST_KUBECONFIG="/root/.kube/config"
#touch "${TEST_KUBECONFIG}"
#chmod 660 "${TEST_KUBECONFIG}"
#export KUBECONFIG="${TEST_KUBECONFIG}"
#cd $VAULT_DIR

#load the images to the cluster
#podman save docker.io/hashicorp/vault-secrets-operator:0.0.0-dev -o vso.tar
#kind load image-archive vso.tar --name vault-secrets-operator
#kubectl rollout restart deployment vault-secrets-operator-controller-manager -n vault-secrets-operator-system

# ----------------------------------------------------------------------------- 
# Step 11.Integration Test setup - Kinldy follow the documentation (Git)
# -----------------------------------------------------------------------------
#make setup-integration-test
## Configure Vault
#./config/samples/setup.sh
#
## Build and deploy the kind
#make deploy-kind

## Deploy the sample K8s resources
#kubectl apply -k config/samples

#make integration-test
