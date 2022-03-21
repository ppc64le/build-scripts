# -----------------------------------------------------------------------------
#
# Package	: github.com/petar/GoLLRB
# Version	: commit #ae3b015
# Source repo	: https://github.com/petar/GoLLRB
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Sandeep Yadav <Sandeep.Yadav10@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

#!/bin/bash

CWD=`pwd`

PACKAGE_PATH=github.com/petar/GoLLRB/llrb
PACKAGE_NAME=GoLLRB/llrb
PACKAGE_VERSION=${1:-53be0d36a84c2a886ca057d34b6aa4468df9ccb4}
PACKAGE_URL=https://github.com/petar/GoLLRB

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

#go mod init
#go mod tidy

#go get github.com/golang/protobuf/proto

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go build -v ./...; then
echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
exit 1
else
echo "------------------$PACKAGE_NAME:install_success-------------------------"
fi

#if ! go build -v ./...; then
#	echo "------------------$PACKAGE_NAME:test_fails---------------------"
#	echo "$PACKAGE_VERSION $PACKAGE_NAME"
#	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
#	exit 1
#fi

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi