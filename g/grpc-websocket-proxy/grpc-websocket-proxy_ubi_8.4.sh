#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tmc/grpc-websocket-proxy
# Version       : 673ab2c3ae75cc01952b84b88590e30e75dcf395
# Source repo   : https://github.com/tmc/grpc-websocket-proxy
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

PACKAGE_PATH=github.com/tmc/
PACKAGE_NAME=grpc-websocket-proxy
PACKAGE_VERSION=${1:-673ab2c3ae75cc01952b84b88590e30e75dcf395}
PACKAGE_URL=https://github.com/tmc/grpc-websocket-proxy

# Install dependencies
yum install -y make git wget gcc

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
        exit 0
fi

echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"
if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    exit 0
fi
