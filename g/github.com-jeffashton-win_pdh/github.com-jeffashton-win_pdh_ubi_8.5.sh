#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/JeffAshton/win_pdh
# Version	: v0.0.0-20161109143554-76bb4ee9f0ab
# Source repo	: https://github.com/jeffashton/win_pdh
# Tested on	: UBI 8.5
# Language	: GO
# Travis-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=github.com/JeffAshton/win_pdh
PACKAGE_VERSION=${1:-v0.0.0-20161109143554-76bb4ee9f0ab}
PACKAGE_URL=https://github.com/jeffashton/win_pdh

yum install -y wget git tar gcc

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $(ls -d $GOPATH/pkg/mod/github.com/\!jeff\!ashton/win_pdh@$PACKAGE_VERSION/)

go mod init $PACKAGE_NAME
go mod tidy

# No test aviable for the Package:
# [root@c41385a53407 win_pdh@v0.0.0-20161109143554-76bb4ee9f0ab]# go test ./...
# no packages to test
