#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : zipkin-go-opentracing
# Version       : v0.4.5
# Source repo   : https://github.com/openzipkin-contrib/zipkin-go-opentracing
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

export PACKAGE_NAME=zipkin-go-opentracing
export PACKAGE_VERSION=${1:-v0.4.5}
export PACKAGE_URL=https://github.com/openzipkin-contrib/zipkin-go-opentracing

dnf install -y git wget gcc make diffutils golang

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME: clone failed-------------------------"
    exit 1
fi
cd $PACKAGE_NAME

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