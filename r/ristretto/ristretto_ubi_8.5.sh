#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: ristretto
# Version	: v0.1.0
# Source repo	: https://github.com/dgraph-io/ristretto
# Tested on	: ubi 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Haritha Patchari <haritha.patchari@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="github.com/dgraph-io/ristretto"
PACKAGE_VERSION=${1:-"v0.1.0"}
PACKAGE_URL="https://github.com/dgraph-io/ristretto"

echo "installing dependencies"
yum install -y gcc-c++ make wget git

#installing golang

wget https://golang.org/dl/go1.13.linux-ppc64le.tar.gz 
tar -C /bin -xf go1.13.linux-ppc64le.tar.gz 
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p $GOPATH/src && cd $GOPATH/src
git clone $PACKAGE_URL
cd ristretto
git checkout $PACKAGE_VERSION

go mod init 
go mod tidy 
go mod vendor

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi
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

