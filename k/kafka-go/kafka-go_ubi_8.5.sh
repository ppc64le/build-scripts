#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : kafka-go
# Version       : v0.2.0
# Source repo   : https://github.com/segmentio/kafka-go.git
# Tested on     : UBI: 8.5
# Language      : GO
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


PACKAGE_NAME=kafka-go
PACKAGE_VERSION=${1:-v0.2.0}
PACKAGE_URL=https://github.com/segmentio/kafka-go.git

yum install go git -y

export GOPATH=/home/tester/go
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

mkdir -p $GOPATH/src/github.com/segmentio && cd $GOPATH/src/github.com/segmentio
rm -rf $PACKAGE_URL
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
go get -u golang.org/x/lint/golint
cp /home/tester/go/bin/golint /usr/bin

go mod init
go mod tidy
if ! go build  ./...; then
    echo "------------------$PACKAGE_NAME: build failed-------------------------"
    exit 1
else
    go get -v -t ./...
    go vet ./...
    echo "------------------$PACKAGE_NAME: build success-------------------------"
fi

if ! go test -v -cover ./...; then
    echo "------------------$PACKAGE_NAME: test failed-------------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  build_&_test_both_success"
fi


# The Build is passing but the test are in Parity with x86.
# batch_test.go:18: failed to open a new kafka connection: dial tcp [::1]:9092: connect: connection refused
# dialer_test.go:225: read tcp 127.0.0.1:57942->127.0.0.1:42217: read: connection reset by peer
