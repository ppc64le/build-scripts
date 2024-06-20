#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : github.com/sigurn/crc16
# Version        : da416fad5162ac0f3338ba24dccdb26e4da22485
# Source repo	 : https://github.com/sigurn/crc16
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

PACKAGE_NAME=crc16
PACKAGE_URL=https://github.com/sigurn/crc16
PACKAGE_VERSION=${1:-da416fad5162ac0f3338ba24dccdb26e4da22485}

PACKAGE_COMMIT_HASH=`echo $PACKAGE_VERSION | cut -d'-' -f3`

GO_VERSION=go1.17.5

yum install -y git wget 

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
mkdir -p $GOPATH/src/github.com/sigurn
cd $GOPATH/src/github.com/sigurn
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_COMMIT_HASH

if ! go mod init; then
	echo "------------------$PACKAGE_NAME:initialize_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Initialize_Fails"
	exit 1
fi

if ! go mod tidy; then
	echo "------------------$PACKAGE_NAME:dependency_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Dependency_Fails"
	exit 1
fi

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
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi