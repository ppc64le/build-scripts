#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-zookeeper
# Version	: v0.0.0-20190923202752-2cc03de413da
# Source repo	: https://github.com/samuel/go-zookeeper
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Anup Kodlekere <Anup.Kodlekere@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=go-zookeeper
PACKAGE_VERSION=${1:-2cc03de413da}
PACKAGE_URL=https://github.com/samuel/go-zookeeper

yum install -y golang git make gcc java-1.8.0-openjdk wget

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init samuel/go-zookeeper
go mod tidy

make setup ZK_VERSION=3.4.12

go build -v ./...

go test -v -timeout 0 -race ./...