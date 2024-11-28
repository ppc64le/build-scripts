#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : milvus-operator
# Version       : v1.1.2
# Source repo   : https://github.com/zilliztech/milvus-operator
# Tested on     : redhat/ubi9:9.3 (docker)
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
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v1.1.2}
PACKAGE_URL=https://github.com/zilliztech/${PACKAGE_NAME}
GO_VERSION=1.21.0
KINDEST_NODE_VERSION=v1.25.3
KIND_VERSION=v0.17.0
TOOL_VERSION=1.0.0
TOOL_RELEASE_IMG=milvusdb/milvus-config-tool:v$TOOL_VERSION
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

echo fs.inotify.max_user_watches=655360 | tee -a /etc/sysctl.conf
echo fs.inotify.max_user_instances=1280 | tee -a /etc/sysctl.conf
systemctl --plain

echo "PACKAGE VERSION "
echo $PACKAGE_VERSION
#Install dependencies
yum update -y
yum install -y --allowerasing git\
    wget \
    gcc  \
    make \
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

#Install Docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
mkdir -p /etc/docker
touch /etc/docker/daemon.json
cat <<EOT > /etc/docker/daemon.json
{
"mtu": 1450
}
EOT
dockerd &
sleep 10
docker run hello-world

#Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-ppc64le
chmod +x ./kind
cp ./kind /usr/bin/
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


#Download source code
cd $wdir

if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi

cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION" || exit 1

#Build
make build-only
go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.14.0
cp $GOPATH/bin/controller-gen $wdir/$PACKAGE_NAME/bin/

#Deploy to kind
kind delete cluster || true
kind create cluster --image=kindest/node:$KINDEST_NODE_VERSION --config=config/kind/kind-dev.yaml


make generate

if ! make build ; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi


if ! make test; then
        echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_success_but_test_fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
fi

if ! make docker-build; then
        echo "------------------$PACKAGE_NAME:docke_build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  docke_build_fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:docker_build_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  docker_build_success"
fi
