#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jsonpatch
# Version	: v0.0.0-20171005235357-81af80346b1a
# Source repo	: https://github.com/mattbaird/jsonpatch.git
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Reynold Vaz <Reynold.Vaz@ibm.com>/ Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jsonpatch
PACKAGE_VERSION=${1:-81af80346b1a}
PACKAGE_URL=https://github.com/mattbaird/jsonpatch.git

yum install go git -y

export GOPATH=/home/tester/go
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

mkdir -p $GOPATH/src/github.com/mattbaird
cd $GOPATH/src/github.com/mattbaird
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! go test -v ./... ; then
	echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
	exit 0
fi