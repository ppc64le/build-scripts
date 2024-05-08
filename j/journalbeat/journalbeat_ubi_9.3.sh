#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: journalbeat
# Version	: master
# Source repo	: https://github.com/mheese/journalbeat
# Tested on	: UBI:9.3 
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=journalbeat
PACKAGE_VERSION=master
PACKAGE_URL=https://github.com/mheese/journalbeat

GO_VERSION=1.21.6

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y wget sudo jq libcurl-devel git make gcc time gnupg2 gcc-c++ python3 systemd-devel
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz 
tar -C  /usr/local -xf go${GO_VERSION}.linux-ppc64le.tar.gz 
export GOROOT=/usr/local/go 
export GOPATH=$HOME 
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH 

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init example.com/m
go mod tidy
go mod vendor

if ! go build ./...; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! go test ./...; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 2
else
        echo "------------------$PACKAGE_NAME:Build_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi
