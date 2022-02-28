#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-hclog
# Version	: v0.9.2, v0.12.2
# Source repo	: https://github.com/hashicorp/go-hclog
# Tested on	: UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=go-hclog
PACKAGE_VERSION=${1:-v0.9.2}
PACKAGE_URL=https://github.com/hashicorp/go-hclog

yum install -y git wget gcc-c++

# Install Go and setup working directory
wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg /home/tester/output

rm -rf go1.17.4.linux-ppc64le.tar.gz
export HOME_DIR=/home/tester

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

cd $HOME_DIR

rm -rf $PACKAGE_NAME

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! git clone $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME: clone failed-------------------------"
	exit 0
fi

cd $PACKAGE_NAME

if ! git checkout $PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME: checkout failed to version $PACKAGE_VERSION-------------------------"
	exit 0
fi

echo `pwd`

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME: build failed-------------------------"
	exit 0
fi

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME: test failed-------------------------"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
