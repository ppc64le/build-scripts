#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : go-sqlmock
# Version       : v1.5.2
# Source repo	: https://github.com/DATA-DOG/go-sqlmock.git
# Tested on     : UBI 9.3
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=go-sqlmock
PACKAGE_VERSION=${1:-v1.5.2}
PACKAGE_URL=https://github.com/DATA-DOG/go-sqlmock.git

yum install -y git wget gcc

export GO_VERSION=${GO_VERSION:-"1.17.13"}  
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
wget "https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz"
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz


git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


go mod tidy

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success"
	exit 0
fi