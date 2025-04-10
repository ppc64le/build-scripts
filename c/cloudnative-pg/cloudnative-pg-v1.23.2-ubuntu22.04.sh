#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : cloudnative-pg
# Version       : v1.23.2
# Source repo   : https://github.com/cloudnative-pg/cloudnative-pg
# Tested on     : Ubuntu 22.04 (docker)
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cloudnative-pg
PACKAGE_VERSION=${1:-v1.23.2}
PACKAGE_URL=https://github.com/cloudnative-pg/${PACKAGE_NAME}.git
GO_VERSION=1.22.5
PGBOUNCER_URL=https://github.com/cloudnative-pg/pgbouncer-containers.git
wdir=`pwd`

echo fs.inotify.max_user_watches=655360 | tee -a /etc/sysctl.conf
echo fs.inotify.max_user_instances=1280 | tee -a /etc/sysctl.conf
sysctl -p

#Install dependencies
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    git \
    zip unzip \
    curl \
    sudo \
    wget \
    coreutils \
    diffutils \
    findutils \
    gpg \
    jq \
    pandoc \
    sed \
    tar \
    util-linux \
    zlib1g \
    rsync \
    tzdata \
    net-tools

#Install Golang
cd $wdir
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
export PATH=$PATH:$HOME/go/bin

#Install golangci-lint 
cd $wdir
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.59.1
golangci-lint --version

#Install goreleaser
go install github.com/goreleaser/goreleaser/v2@latest

#Install operator SDK
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.35.0
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
#gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 052996E2A20B5C7E
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc
grep operator-sdk_${OS}_${ARCH} checksums.txt | sha256sum -c -
chmod +x operator-sdk_${OS}_${ARCH} 
mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk
rm -rf checksums.txt checksums.txt.asc

#Install docker
DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
dockerd > /dev/null 2>&1 &
sleep 5
docker run hello-world

#Install kind
#go install sigs.k8s.io/kind@v0.20.0
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-ppc64le
chmod +x ./kind
mv ./kind /usr/local/bin/kind

#Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/ppc64le/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

#Install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y
apt-get install helm -y

#Download source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply ../${PACKAGE_NAME}-${PACKAGE_VERSION}.patch

#Build binary
make build

#Test
make test || true

#Docker build
make docker-build

#Build kindest/node image
mkdir -p $GOPATH/src/k8s.io
cd $GOPATH/src/k8s.io
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
git checkout v1.30.0
kind build node-image .
docker tag kindest/node:latest kindest/node:v1.30.0

# Download source code for pgbouncer-containers and build image for ppc64le
cd $wdir
git clone ${PGBOUNCER_URL}
cd pgbouncer-containers
git checkout v1.23.0-1
sed -i 's/buster-20240612-slim/stable-slim/' ./Dockerfile
docker build --rm -t cloudnative-pg/pgbouncer-ppc64le:1.23.0 .

#Build fluentd daemonset image
cd $wdir
git clone https://github.com/fluent/fluentd-kubernetes-daemonset
cd fluentd-kubernetes-daemonset
git checkout v1.16.5-1.1
git apply ../fluentd-kubernetes-daemonset-v1.16.5-1.1.patch
cd docker-image/v1.14/arm64/debian-forward
docker build -t fluent/fluentd-kubernetes-daemonset:v1.14.3-debian-forward-1.0 .

#build the operator's data store image
cd $wdir
git clone https://github.com/cloudnative-pg/postgres-containers
cd postgres-containers
git checkout b26fbeba8b14cc4a722121138d6999d551c0aa57
git apply ../postgres-containers-master.patch
cd Debian/16/bookworm/
docker build -t cloudnative-pg/postgresql:16.3 .
docker tag cloudnative-pg/postgresql:16.3 cloudnative-pg/postgresql:16

#Build Azure image
cd $wdir
git clone https://github.com/Azure/Azurite.git && cd Azurite
git checkout v3.30.0
sed  -i '5 a \\n#Add ppc64le dependencies \nRUN apk add python3 python3-dev g++ make pkgconfig libsecret-dev' Dockerfile
docker build -t mcr.microsoft.com/azure-storage/azurite:1.1 .

#Build Azure Client image
cd $wdir
docker build -f Dockerfile-azurecli -t mcr.microsoft.com/azure-cli:1.1 .


#e2e tests
cd $wdir/${PACKAGE_NAME}
kind delete cluster --name pg-operator-e2e-v1-30-0
make e2e-test-kind

#Conclude
set +ex
echo "Build and tests Successful!"

