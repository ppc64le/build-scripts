#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: technicianted/archiver
# Version	: v3.3.1-0.20191128232702-fcf9876e4d2f
# Source repo	: https://github.com/technicianted/archiver
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

PACKAGE_NAME=archiver
PACKAGE_VERSION=${1:-fcf9876e4d2f}
PACKAGE_URL=https://github.com/technicianted/archiver

yum install -y git wget gcc

GO_VERSION=1.17

##install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH

cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go get -v github.com/golangci/golangci-lint/cmd/golangci-lint

#Build and test
go get -v -t -d ./...
go test -race ./...

