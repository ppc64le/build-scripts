#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : go-acme/lego
# Version	 : v2.5.0
# Source repo	 : https://github.com/go-acme/lego
# Tested on	 : UBI 8.5
# Language       : GO
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer	 : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/go-acme/lego
PACKAGE_URL=https://github.com/go-acme/lego
PACKAGE_VERSION=${1:-v4.8.0}

GO_VERSION=go1.18.5

yum install -y git wget make gcc-c++

# install go
rm -rf /bin/go
wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz

# set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

# install lego package
mkdir -p `dirname $PACKAGE_NAME` && cd `dirname $PACKAGE_NAME`
git clone $PACKAGE_URL
cd `basename $PACKAGE_NAME`
go get -tags $PACKAGE_VERSION -t ./...

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi


if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi