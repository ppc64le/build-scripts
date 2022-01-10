# -----------------------------------------------------------------------------
#
# Package	: google.golang.org/protobuf
# Version	: v1.27.1, v1.23.0
# Source repo	: https://github.com/protocolbuffers/protobuf-go
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=google.golang.org/protobuf
PACKAGE_VERSION=${1:-v1.27.1}

set -e

yum install -y git golang

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Get_Fails"
	exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! go install ./...; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

# 1 Test Failure with version v1.23.0, in parity with Intel
# proto/testmessages_test.go:821:44: conversion from untyped int to String (string) yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! go test ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
	exit 0
fi
