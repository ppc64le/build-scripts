#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: lightstep-tracer-common
# Version	: v0.0.0-20190605223551-bc2310a04743
# Source repo	: https://github.com/lightstep/lightstep-tracer-common
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar/Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=lightstep-tracer-common
PACKAGE_VERSION=${1:-bc2310a04743}
PACKAGE_URL=https://github.com/lightstep/lightstep-tracer-common

yum install -y git make wget gcc

GO_VERSION=1.17

##install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 


export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on
export GOPROXY=https://proxy.golang.org

cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


#Build and Test
cd golang/gogo
go build
go get google.golang.org/grpc/internal/channelz@v1.21.0
go test -v ./...
cd ..

cd protobuf
go build
go get google.golang.org/grpc/internal/channelz@v1.21.0
go get google.golang.org/protobuf
go test -v ./...
