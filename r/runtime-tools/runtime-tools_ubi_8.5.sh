#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: runtime-tools
# Version	: v0.0.0-20181011054405-1d69bd0f9c39
# Source repo	: https://github.com/opencontainers/runtime-tools
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

PACKAGE_NAME=runtime-tools
PACKAGE_VERSION=${1:-1d69bd0f9c39}
PACKAGE_URL=https://github.com/opencontainers/runtime-tools

yum install -y git make wget gcc

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

mkdir --parents $GOPATH/src/golang.org/x
git clone --depth=1 https://go.googlesource.com/lint $GOPATH/bin/golang.org/x/lint
go install golang.org/x/lint/golint@latest
go get golang.org/x/tools
##go install golang.org/x/tools@latest

##Build and test
go mod init
go mod tidy
go mod vendor
make

#go build ./... also can be used
#The command 'make test' fails since the tests it fails for are written for windows platform,
#hence 'go test -race ./...' command is used to test the package.

go test -race ./...
