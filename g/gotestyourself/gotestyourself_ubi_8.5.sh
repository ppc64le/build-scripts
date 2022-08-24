#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : gotestyourself
# Version       : v2.2.0+incompatible
# Source repo   : https://github.com/gotestyourself/gotestyourself
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License:  Apache License, Version 2 or later
# Maintainer    : Haritha Patchari <haritha.patchari@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#VARIABLES
PACKAGE_NAME=gotestyourself
PACKAGE_VERSION=${1:-v2.2.0+incompatible}
PACKAGE_URL=https://github.com/gotestyourself/gotestyourself

# Install dependencies
yum -y update && yum install git gcc make wget tar zip -y

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi
echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi


