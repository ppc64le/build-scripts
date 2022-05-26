#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/hashicorp/consul/sdk
# Version	: v0.3.0
# Source repo	: https://github.com/hashicorp/consul
# Tested on	: UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=sdk
PACKAGE_VERSION=${1:-sdk/v0.4.0}
PACKAGE_URL=https://github.com/hashicorp/consul

yum install -y wget tar zip gcc-c++ make git procps diffutils

wget https://golang.org/dl/go1.17.5.linux-ppc64le.tar.gz
tar -C /bin -xf go1.17.5.linux-ppc64le.tar.gz

mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.45.2
go install gotest.tools/gotestsum@latest

git clone $PACKAGE_URL
cd consul
git checkout $PACKAGE_VERSION
go mod download

make tools
make dev

ulimit -n 2048
umask 0022

cd $PACKAGE_NAME

if ! gotestsum   --format=short-verbose ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi
