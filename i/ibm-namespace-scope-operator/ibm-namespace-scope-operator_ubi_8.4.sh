#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : IBM/ibm-namespace-scope-operator
# Version       : v1.0.1
# Source repo   : https://github.com/IBM/ibm-namespace-scope-operator
# Tested on     : RHEL ubi 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Apurva Agrawal <Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_PATH=github.com/IBM/
PACKAGE_NAME=ibm-namespace-scope-operator
PACKAGE_VERSION=v1.0.1
PACKAGE_URL=https://github.com/IBM/ibm-namespace-scope-operator

# Install dependencies
yum install -y make git wget gcc

# Install unit test dependencies and run unit tests
mkdir $CWD/kubebuilder-tools
cd $CWD/kubebuilder-tools

wget https://github.com/kubernetes-sigs/kubebuilder/releases/download/v2.3.1/kubebuilder_2.3.1_linux_ppc64le.tar.gz
tar -xzf kubebuilder_2.3.1_linux_ppc64le.tar.gz
cp kubebuilder_2.3.1_linux_ppc64le/bin/kubebuilder .
rm -rf kubebuilder_2.3.1_linux_ppc64le.tar.gz kubebuilder_2.3.1_linux_ppc64le

wget https://dl.k8s.io/v1.19.0/kubernetes-server-linux-ppc64le.tar.gz
tar -xzf kubernetes-server-linux-ppc64le.tar.gz
cp kubernetes/server/bin/kube-apiserver .
rm -rf kubernetes-server-linux-ppc64le.tar.gz kubernetes

wget https://github.com/etcd-io/etcd/releases/download/v3.4.14/etcd-v3.4.14-linux-ppc64le.tar.gz
tar -xzf etcd-v3.4.14-linux-ppc64le.tar.gz
cp etcd-v3.4.14-linux-ppc64le/etcd .
rm -rf etcd-v3.4.14-linux-ppc64le.tar.gz etcd-v3.4.14-linux-ppc64le

export KUBEBUILDER_ASSETS=$CWD/kubebuilder-tools

# Download and install go
wget https://golang.org/dl/go1.17.5.linux-ppc64le.tar.gz
tar -xzf go1.17.5.linux-ppc64le.tar.gz
rm -rf go1.17.5.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

# Clone the repo and checkout submodules
mkdir -p $GOPATH/src/$PACKAGE_PATH
cd $GOPATH/src/$PACKAGE_PATH
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go build -v ./...; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        exit 1
fi

echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"
go mod init
go mod tidy
if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        exit 0
fi
