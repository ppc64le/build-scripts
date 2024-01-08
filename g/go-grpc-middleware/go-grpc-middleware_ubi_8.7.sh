#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : go-grpc-middleware
# Version          : v2.0.1
# Source repo      : https://github.com/grpc-ecosystem/go-grpc-middleware
# Tested on	: UBI 8.7
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=go-grpc-middleware
PACKAGE_VERSION=${1:-v2.0.1}
PACKAGE_URL=https://github.com/grpc-ecosystem/go-grpc-middleware

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git gcc wget
export GO_VERSION=${GO_VERSION:-1.20.1}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin

wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod tidy

if ! go build ./...; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Init_Fails"
	exit 1
fi

if ! go test ./...; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi
