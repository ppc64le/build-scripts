#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : golang_protobuf_extensions
# Version       : fc2b8d3a73c4867e51861bbdd5ae3c1f0869dd6a
# Source repo   : https://github.com/matttproud/golang_protobuf_extensions
# Tested on     : UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <shreya.kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=golang_protobuf_extensions
PACKAGE_VERSION=${1:-fc2b8d3a73c4867e51861bbdd5ae3c1f0869dd6a}
PACKAGE_URL=https://github.com/matttproud/golang_protobuf_extensions

#Install the required dependencies
yum -y update && yum install git gcc make wget tar zip -y
GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

#export GOPATH=/home/runner/go
export GOPATH=/usr/bin/go/
export PATH=$GOPATH/bin:$PATH

#Setup working directory
mkdir -p $GOPATH/src/github.com/shirou && cd $GOPATH/src/github.com/shirou

#Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init github.com/matttproud/golang_protobuf_extensions
go mod tidy
go get google.golang.org/protobuf/proto
go get github.com/matttproud/golang_protobuf_extensions/pbtest

go get -t -v ./...

if ! go build ./...; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
fi

if ! go test ./... ; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    exit 0
fi
