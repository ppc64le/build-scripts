#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	     : cloudflare/cfssl
# Version	     : v1.6.2
# Source repo	 : https://github.com/cloudflare/cfssl/
# Tested on	     : UBI 8.5
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

PACKAGE_NAME=cfssl
PACKAGE_URL=https://github.com/cloudflare/cfssl/
PACKAGE_VERSION=${1:-v1.6.2}

GO_VERSION=go1.18.6

yum install -y git wget make gcc-c++

#install go
rm -rf /bin/go
wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz

#set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
mkdir -p /home/tester/go
cd $GOPATH

#clone package
mkdir -p $GOPATH/src/github.com/cloudflare
cd $GOPATH/src/github.com/cloudflare
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export GOFLAGS="-mod=vendor"
export GODEBUG="x509sha1=1"

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi

chmod +x test.sh
if ! ./test.sh; then
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