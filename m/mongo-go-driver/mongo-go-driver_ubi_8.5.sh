#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : mongo-go-driver
# Version       : v1.1.3
# Source repo   : https://github.com/mongodb/mongo-go-driver
# Tested on     : UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
export PACKAGE_VERSION=${1:-v1.1.3}
export PACKAGE_NAME=mongo-go-driver
export PACKAGE_URL=https://github.com/mongodb/mongo-go-driver
export HOME_DIR=/home/tester
export GO111MODULE=on

dnf install -y git wget gcc make diffutils golang

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME: clone failed-------------------------"
    exit 1
fi
cd $PACKAGE_NAME

if ! go mod init; then
    echo "------------------$PACKAGE_NAME: mod init failed-------------------------"
    exit 1
fi

if ! go mod tidy; then
    echo "------------------$PACKAGE_NAME: mod tidy failed-------------------------"
    exit 1
fi
if ! go mod vendor; then
    echo "------------------$PACKAGE_NAME: mod vendor failed-------------------------"
    exit 1
fi
if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME: build failed-------------------------"
    exit 1
fi
if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME: test failed-------------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  build_&_test_both_success"
fi