#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : kit
# Version       : v0.12.0, v0.10.0, v0.9.0
# Source repo	: https://github.com/go-kit/kit
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Nageswara Rao K<nagesh4193@gmail.com>/ Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=kit
PACKAGE_URL=https://github.com/go-kit/kit
PACKAGE_VERSION=${1:-v0.9.0}

# Dependency installation
dnf install -y git golang 

# Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME

go get -tags $PACKAGE_VERSION -t ./...

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi 