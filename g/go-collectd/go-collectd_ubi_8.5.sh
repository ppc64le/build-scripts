#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : go-collectd
# Version       : v0.1.0
# Source repo   : https://github.com/collectd/go-collectd.git
# Tested on     : UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ambuj Kumar <Ambuj.Kumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

export PACKAGE_NAME=go-collectd
export PACKAGE_VERSION=${1:-v0.1.0}
export PACKAGE_URL=https://github.com/collectd/go-collectd.git

dnf install -y git wget gcc make diffutils golang
export GOPATH=/home/tester/go
export PATH=$PATH:$GOPATH/bin

mkdir -p $GOPATH/src/github.com/collectd && cd $GOPATH/src/github.com/collectd
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.43.0

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME: clone failed-------------------------"
    exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
export COLLECTD_SRC="$GOPATH/src/github.com/collectd/go-collectd"
export CGO_CPPFLAGS="-I${COLLECTD_SRC}/src/daemon -I${COLLECTD_SRC}/src"
go mod init
go mod tidy

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME: test failed-------------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  build_&_test_both_success"
fi

# Lower version of package go-collectd both build and test passed successfully
# Request version got the issue in plugin package in this repositorary
# plugin/c.go:7:11: fatal error: plugin.h: No such file or directory, except of plugin package other packages build and test passed.


