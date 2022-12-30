#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-pipeline-go
# Version       : v0.2.2
# Source repo   : https://github.com/Azure/azure-pipeline-go
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas Gupta <vikas.gupta8@ibm.com>/ Balavva Mirji <Balavva.Mirji@ibm.com>
# Language 	: GO
# Travis-Check  : True
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=azure-pipeline-go
PACKAGE_VERSION=${1:-v0.2.2}
PACKAGE_URL=https://github.com/Azure/azure-pipeline-go

yum install -y git wget tar gcc-c++

wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

rm -rf go1.17.4.linux-ppc64le.tar.gz

mkdir -p /home/tester/output
export HOME_DIR=/home/tester
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

cd $HOME_DIR
rm -rf $PACKAGE_NAME

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"

if ! git clone $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
	exit 0
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo `pwd`

go mod tidy

# building
echo "Building and Testing $PACKAGE_NAME with $PACKAGE_VERSION"

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME: build and  Test failed-------------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi
