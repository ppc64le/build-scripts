#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : vault-k8s
# Version       : 1.2.1
# Source repo   : https://github.com/hashicorp/vault-k8s
# Tested on     : UBI 8.7
# Language      : Go 
# Ci-Check  : True
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

PACKAGE_NAME=vault-k8s
PACKAGE_VERSION=${1:-1.2.1}
PACKAGE_URL=https://github.com/hashicorp/vault-k8s
GO_VERSION=1.20.5

#Install dependencies
dnf install -y \
    gcc \
    gcc-c++ \
    git \
    make \
    wget 

wdir=`pwd`

#Download source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout v${PACKAGE_VERSION}

#Install Golang
cd $wdir
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
export PATH=$PATH:$HOME/go/bin

#Install docker
#Remove the following packages if you experience docker conflicts
#yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker
docker run hello-world

#Build vault-k8s
cd $wdir/${PACKAGE_NAME}
export VERSION=${PACKAGE_VERSION}
export GOARCH=ppc64le
export VAULTK8S_BIN=$wdir/${PACKAGE_NAME}/dist/${PACKAGE_NAME}
make build

#Smoke test binary
$VAULTK8S_BIN version

#Test
export CGO_ENABLED=1
make test

#Build docker image
export IMAGE_TAG=vault-k8s-${GOARCH}:${VERSION}
make -o build image

#Smoke test docker image
docker run --rm $IMAGE_TAG version

#Conclude
echo "Build and test successful!"
echo "vault-k8s binary available at [$VAULTK8S_BIN]"
echo "vault-k8s docker image tagged as [$IMAGE_TAG]"

