#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : cloudnative-pg
# Version       : v1.23.2
# Source repo   : https://github.com/cloudnative-pg/cloudnative-pg
# Tested on     : RHEL 9.3
# Language      : Go
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Soham Badjate <soham.badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

wdir=$(pwd)
PACKAGE_NAME=cloudnative-pg
PACKAGE_VERSION=${1:-release-1.25}
PACKAGE_URL=https://github.com/cloudnative-pg/${PACKAGE_NAME}.git
GO_VERSION=1.22.5
PGBOUNCER_URL=https://github.com/cloudnative-pg/pgbouncer-containers.git

# Install dependencies required for cloudnative-pg
dnf install -y git make gcc postgresql-devel wget postgresql rsync jq
wget https://download.docker.com/linux/centos/docker-ce.repo
mv docker-ce.repo /etc/yum.repos.d/ && yum -y install docker-ce

# Install Operator-SDK 
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.35.0
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 052996E2A20B5C7E
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc
grep operator-sdk_${OS}_${ARCH} checksums.txt | sha256sum -c -
chmod +x operator-sdk_${OS}_${ARCH}
mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk
rm -rf checksums.txt checksums.txt.asc

# Install go version 1.24.5
curl -LO https://go.dev/dl/go1.24.5.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.24.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin:/root/go/bin
source ~/.bashrc
GOPATH=$(go env GOPATH)

# Install kubectl required for testing
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/ppc64le/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install helm required for testing
HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-ppc64le.tar.gz"
tar -zxvf helm-${HELM_VERSION}-linux-ppc64le.tar.gz
mv linux-ppc64le/helm /usr/local/bin/
rm -rf linux-ppc64le helm-${HELM_VERSION}-linux-ppc64le.tar.gz
helm version

# Install kind required for testing
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-ppc64le
chmod +x ./kind
mv ./kind /usr/local/bin/kind


# Install kubebuilder required for testing
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(uname -s)/$(uname -m)"
chmod +x kubebuilder
mv kubebuilder /usr/local/bin/
kubebuilder version

# Create directory for test binaries and install kubebuilder-tools
KUBEBUILDER_TOOLS_VERSION=1.28.0
mkdir -p /usr/local/kubebuilder/bin
curl -L https://storage.googleapis.com/kubebuilder-tools/kubebuilder-tools-${KUBEBUILDER_TOOLS_VERSION}-linux-ppc64le.tar.gz -o kubebuilder-tools.tar.gz
tar -zxvf kubebuilder-tools.tar.gz
cp -r kubebuilder/bin/* /usr/local/kubebuilder/bin/
rm -rf kubebuilder-tools.tar.gz kubebuilder
echo 'export KUBEBUILDER_ASSETS="/usr/local/kubebuilder/bin"' >> ~/.bashrc
source ~/.bashrc

# Build postgres containers image required for testing
cd $wdir
wget https://raw.githubusercontent.com/sohambadjate-IBM/build-scripts/master/c/cloudnative-pg/postgres-containers_master-e72801a.patch
git clone https://github.com/cloudnative-pg/postgres-containers.git && cd postgres-containers
git checkout e72801ac672e8a33544a15d0c26b9036571cb3f7
git apply ../postgres-containers_master-e72801a.patch
cd /postgres-containers/Debian/17/bookworm/ && docker build -t cloudnative-pg/postgresql:17.6-system-trixie .


#                               If you encounter any buildx errors, please uncomment the code below.
# cd $wdir
# docker buildx create --name=attestation-builder --driver=docker-container --use
# docker buildx inspect attestation-builder --bootstrap

# Build/Pull kind-node image required for e2e tests
docker pull quay.io/powercloud/kind-node:v1.33.5
docker tag quay.io/powercloud/kind-node:v1.33.5 kindest/node:v1.33.2

#        If you want to build your own kindest/node image, please uncomment the code below and comment out the above pull commands
# mkdir -p $GOPATH/src/k8s.io
# cd $GOPATH/src/k8s.io
# git clone https://github.com/kubernetes/kubernetes
# cd kubernetes
# git checkout v1.33.2
# kind build node-image -t kindest/node:v1.33.2 .


# Build pgbouncer image
cd $wdir
git clone ${PGBOUNCER_URL}
cd pgbouncer-containers
git checkout v1.24.1-20
sed -i 's|RUN  curl -sL http://www.pgbouncer.org/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz > pgbouncer.tar.gz ; \\|RUN wget --no-check-certificate https://www.pgbouncer.org/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz -O pgbouncer.tar.gz ; \\|' Dockerfile
sed -i 's/\bcurl\b/wget/g' Dockerfile
docker build --rm -t cloudnative-pg/pgbouncer-ppc64le:1.24.1 .

# Build/Pull fluentd-kubernetes image required for e2e tests
docker pull prachigaonkar/fluentd-kubernetes-daemonset:v1.14.3-debian-forward-1.0
docker tag prachigaonkar/fluentd-kubernetes-daemonset:v1.14.3-debian-forward-1.0 fluent/fluentd-kubernetes-daemonset:v1.18.0-1.5-debian-forward-1.0

#        If you want to build your own kindest/node image, please uncomment the code below and comment out the above pull commands
# cd $wdir
# git clone https://github.com/fluent/fluentd-kubernetes-daemonset
# cd fluentd-kubernetes-daemonset
# git checkout v1.18.0-1.5
# cd docker-image/v1.18/arm64/debian-forward
# docker build -t fluent/fluentd-kubernetes-daemonset:v1.18.0-1.5-debian-forward-1.0 .

# Build Azurite image  required for e2e testing
cd $wdir
git clone https://github.com/Azure/Azurite.git && cd Azurite
git checkout v3.33.0
sed  -i '5 a \\n#Add ppc64le dependencies \nRUN apk add python3 python3-dev g++ make pkgconfig libsecret-dev' Dockerfile
docker build -t mcr.microsoft.com/azure-storage/azurite:1.1 .

# Build Azure Cli image required for testing
cd $wdir
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cloudnative-pg/Dockerfile-azurecli
docker build -f Dockerfile-azurecli -t mcr.microsoft.com/azure-cli:1.1 .


# Clone Repository and apply patch
cd $wdir
wget https://raw.githubusercontent.com/sohambadjate-IBM/build-scripts/master/c/cloudnative-pg/cloudnative-pg_release-1.25.patch
git clone ${PACKAGE_URL}
cd cloudnative-pg/
git checkout 0780b6d2666e78dee1a1c11bfa9df3d4c651a61f #release-1.25
git apply ../cloudnative-pg_release-1.25.patch

# Install required Go packages and export Variables
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/goreleaser/goreleaser/v2@latest
git tag cnpg
export PLATFORM="ppc64le"
export VERSION="1.25.3"
export GOOS=linux GOARCH=${PLATFORM} GOPATH=$(go env GOPATH) DATE=$(date +"%Y-%m-%d") COMMIT=$(git rev-parse --short HEAD) VERSION=${VERSION}

# Build binaries and Docker image 
if ! make build && goreleaser build --skip=validate --clean --single-target && docker buildx build --platform ${PLATFORM} --tag cloudnative-pg/cloudnative-pg:${VERSION} --load .; then
    echo "------------------$PACKAGE_NAME: Build_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Failure"
    exit 1
fi

# Run Unit Test
if ! make test ; then
    echo "------------------$PACKAGE_NAME: Unit Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2
# Run e2e test (will fail)
elif ! make e2e-test-kind ; then
    echo "------------------$PACKAGE_NAME: E2E Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2

else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi

set +ex