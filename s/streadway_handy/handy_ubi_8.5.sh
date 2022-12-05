#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : handy
# Version       : 0f66f006fb2e
# Source repo   : https://github.com/streadway/handy.git
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

PACKAGE_NAME=handy
PACKAGE_VERSION=${1:-0f66f006fb2e}
GO_VERSION=1.17.4
ARCH=ppc64le
PACKAGE_URL=https://github.com/streadway/handy.git

dnf install gcc gcc-c++ make git wget sudo unzip -y

mkdir -p /home/tester/output
cd /home/tester

wget https://golang.org/dl/go$GO_VERSION.linux-$ARCH.tar.gz
rm -rf /usr/local/go && tar -C /usr/local/ -xzf go$GO_VERSION.linux-$ARCH.tar.gz
rm -rf go$GO_VERSION.linux-$ARCH.tar.gz
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-/home/tester/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
export GO111MODULE=on
mkdir -p $GOPATH/src/github.com/streadway
cd $GOPATH/src/github.com/streadway

rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone $PACKAGE_URL $PACKAGE_NAME;

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init && go mod tidy
go build

go test -v ./...