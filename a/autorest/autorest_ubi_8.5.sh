#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/azure/go-autorest/autorest
# Version	: v0.11.23 , v0.11.19
# Source repo	: https://github.com/Azure/go-autorest
# Tested on	: UBI 8.5
# Language	: GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Requested version v0.9.0 has some test failure(which is in parity)
# However the latest released version v0.11.23 has build and test success.
# ----------------------------------------------------------------------------


PACKAGE_NAME=github.com/Azure/go-autorest/autorest
PACKAGE_VERSION=${1:-v0.11.23}
PACKAGE_URL=https://github.com/Azure/go-autorest
PACKAGE_PATH=go-autorest/autorest

yum install -y wget git tar gcc

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

#running the go commands
cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_PATH
git checkout autorest/$PACKAGE_VERSION


if ! go build ./...; then
	echo "------------------$PACKAGE_NAME:Build_Fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! go test ./... -v; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
	exit 1
else		
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
