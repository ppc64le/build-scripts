#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : activemq-artemis-operator
# Version           : amq-broker-7.13.0.OPR.1.CR3
# Source repo       : https://github.com/rh-messaging/activemq-artemis-operator
# Tested on         : UBI:9.3
# Language          : Go
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Bharti Somra(Bharti.Somra@ibm.com)
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------
#

PACKAGE_NAME=activemq-artemis-operator
PACKAGE_URL=https://github.com/rh-messaging/activemq-artemis-operator
PACKAGE_VERSION=${1:-amq-broker-7.13.0.OPR.1.CR3}

SDK_PACKAGE_NAME=operator-sdk
SDK_PACKAGE_URL=https://github.com/operator-framework/operator-sdk
SDK_PACKAGE_VERSION=${1:-v1.28.0}

GO_VERSION=1.22.7

dnf update -y  && dnf install -y git wget gcc-c++ gcc make

#Go installation
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH
export PATH=$PATH:$HOME/go/bin
export GOBIN=$(go env GOPATH)/bin
go version

#operator-sdk
git clone $SDK_PACKAGE_URL
cd $SDK_PACKAGE_NAME
git checkout $SDK_PACKAGE_VERSION
make install
cd ../

#Check if package exists
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
#ppc64 supported version of kustomize
sed -i "s/v3.8.7/v5.4.1/g" Makefile

#building and testing
if ! make build ; then
    echo "------------------$PACKAGE_NAME:Install_Failure---------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Failure"
        exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

