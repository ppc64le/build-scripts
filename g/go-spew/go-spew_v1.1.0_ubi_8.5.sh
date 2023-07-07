#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-spew
# Version	: v1.1.0
# Source repo	: https://github.com/davecgh/go-spew
# Tested on     : UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Valen Mascarenhas / Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=go-spew
PACKAGE_VERSION=${1:-v1.1.0}
PACKAGE_URL=github.com/davecgh/go-spew

yum install -y git golang


go get -d -t $PACKAGE_URL@$PACKAGE_VERSION

cd ~/go/pkg/mod/$PACKAGE_URL*

go mod init $PACKAGE_URL

go build ./...

if ! go test ./...; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Build_and_Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
	exit 0
fi
