#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : go-genproto
# Version       : b5d43981345bdb2c233eb4bf3277847b48c6fdc6,d950eab6f860f209ea1641dee947bb9f7009e120,4f43b3371335a8c62857680af0dfbfa8e97139ae
# Source repo   : https://github.com/googleapis/go-genproto
# Tested on     : UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Apurva Agrawal <apurva.agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_PATH=github.com/googleapis/
PACKAGE_NAME=go-genproto
PACKAGE_VERSION=${1:-b5d43981345bdb2c233eb4bf3277847b48c6fdc6}
PACKAGE_URL=https://github.com/googleapis/go-genproto

# Install dependencies
yum install -y make git wget

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
go mod init 
go mod tidy
if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	exit 1
fi

echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    exit 0
fi
