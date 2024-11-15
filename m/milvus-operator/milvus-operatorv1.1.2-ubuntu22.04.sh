#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : milvus-operator
# Version       : v1.1.2
# Source repo   : https://github.com/zilliztech/milvus-operator
# Tested on     : Ubuntu 22.04 (docker)
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Kavita Rane <Kavita.Rane2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=milvus-operator
PACKAGE_VERSION=v1.1.2
PACKAGE_URL=https://github.com/zilliztech/${PACKAGE_NAME}
GO_VERSION=1.21.0
KINDEST_NODE_VERSION=v1.25.3
K8SSANDRA_CLIENT_VERSION=v0.2.2
MGMT_API_VERSION=v0.1.73
KIND_VERSION=v0.17.0
CASS_CONFIG_BUILDER_VERSION=v1.0.8
CASS_CONFIG_DEFS_VERSION=1b7eaf4e50447fc8168c4a6c16d0ed986941edf8
CERT_MANAGER_VERSION=v1.12.2
TOOL_VERSION=1.0.0
TOOL_RELEASE_IMG=milvusdb/milvus-config-tool:v$TOOL_VERSION

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
    rsync \
    tzdata \
    net-tools

wdir=`pwd`

#Install Golang
cd $wdir
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
export PATH=$PATH:$HOME/go/bin
export GOPATH=${GOPATH:-$HOME/go}

#Install docker
DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl gnupg lsb-release init -y
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
dockerd > /dev/null 2>&1 &
sleep 5
docker run hello-world

#Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-ppc64le
chmod +x ./kind
mv ./kind /usr/local/bin/kind

#Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/ppc64le/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

#Install yq
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_ppc64le
chmod a+x /usr/local/bin/yq

#Build kindest/node image
mkdir -p $GOPATH/src/k8s.io
cd $GOPATH/src/k8s.io
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
git checkout $KINDEST_NODE_VERSION
kind build node-image .
docker tag kindest/node:latest kindest/node:$KINDEST_NODE_VERSION


#Deploy to kind
#cd $wdir/${PACKAGE_NAME}
#kind delete cluster || true
#kind create cluster --image=kindest/node:$KINDEST_NODE_VERSION --config=$dwdir/kind.yaml


#Download source code
cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
make build-only
go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.14.0
cp $GOPATH/bin/controller-gen $wdir/$PACKAGE_NAME/bin/

#Deploy to kind
kind delete cluster || true
kind create cluster --image=kindest/node:$KINDEST_NODE_VERSION --config=config/kind/kind-dev.yaml


make generate
make build
#Unit tests
make test

make docker-build
docker tag milvusdb/milvus-operator:dev-latest milvusdb/milvus-operator:v2.4.13
docker tag milvusdb/milvus-operator:dev-latest milvusdb/milvus-operator:v1.1.0
