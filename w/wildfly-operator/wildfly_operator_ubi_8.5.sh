#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : wildfly-operator
# Version       : 0.5.6
# Source repo   : https://github.com/wildfly/wildfly-operator/
# Tested on     : UBI 8.6
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=wildfly-operator
PACKAGE_VERSION=${1:-0.5.6}
PACKAGE_URL=https://github.com/wildfly/wildfly-operator.git

yum install -y git gcc wget make

GO_VERSION=${GO_VERSION:-1.19.4}

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

if ! git clone $PACKAGE_URL $GOPATH/src/github.com/wildfly/wildfly-operator; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $GOPATH/src/github.com/wildfly/wildfly-operator

git checkout $PACKAGE_VERSION

if ! make build; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

#e2e tests has dependency on below images which are not available for Power -
#quay.io/operator-framework/scorecard-test:v1.3.1
#quay.io/wildfly-quickstarts/wildfly-operator-quickstart:bootable-21.0
#quay.io/wildfly-quickstarts/clusterbench:latest

#Minikube setup is required for E2E tests execution commenting this as minikube doesnt work within container. 
# Steps for Minikube Setup -
#1. curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-ppc64le
#2. sudo install minikube-linux-ppc64le /usr/local/bin/minikube
#3. minikube start --driver=docker - to start mimnikube container
#4. minikube status - check minikube status running and configured

#For E2E tests run -
#eval $(minikube -p minikube docker-env) && make test-e2e-minikube
