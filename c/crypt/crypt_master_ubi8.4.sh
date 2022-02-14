#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : crypt
# Version        : master
#     The version v0.0.3-0.20170626215501-b2862e3d0a77 isn't released on github.
#     Current head as on Feb 14, 2021 is at commit id b2862e3d0a77.
# Source repo    : https://github.com/xordataexchange/crypt
# Tested on        : UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prashant Khoje <prashant.khoje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

export PACKAGE_NAME=crypt
# The version v0.0.3-0.20170626215501-b2862e3d0a77 isn't released on github.
# Current head as on Feb 11, 2021 is at commit id b2862e3d0a77.
export PACKAGE_VERSION=${1:-master}
export PACKAGE_URL=https://github.com/xordataexchange/crypt

export HOME_DIR=/home/tester

export GO_DIR=/bin
export GO_VERSION=1.12.17
# Also works with 
# export GO_VERSION=1.12.4
export GOPATH=/home/tester/go
export GOROOT=$GO_DIR/go
export GO111MODULE=on

export PATH=$PATH:/bin/go/bin
export PATH=$GOPATH/bin:$PATH

yum install -y git wget gcc

# Install Go and setup working directory
wget https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C $GO_DIR -xf go$GO_VERSION.linux-ppc64le.tar.gz && \
    mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg $HOME_DIR/output
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

cd $HOME_DIR
rm -rf $PACKAGE_NAME

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME: clone failed-------------------------"
    exit 1
fi

cd $PACKAGE_NAME

if ! git checkout $PACKAGE_VERSION; then
    echo "------------------$PACKAGE_NAME: checkout failed to version $PACKAGE_VERSION-------------------------"
    exit 1
fi

echo `pwd`

if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME: build failed-------------------------"
    exit 1
fi

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME: test failed-------------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME" > $HOME_DIR/output/test_success 
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success" > $HOME_DIR/output/version_tracker
fi

