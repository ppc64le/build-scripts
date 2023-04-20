#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : kiegroup/kie-cloud-operator
# Version       : 7.13.2-2
# Source repo   : https://github.com/kiegroup/kie-cloud-operator.git
# Tested on     : UBI 8.6
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
  
PACKAGE_NAME=kie-cloud-operator
PACKAGE_VERSION=${1:-7.13.2-2}
PACKAGE_URL=https://github.com/kiegroup/kie-cloud-operator.git

yum install -y git wget make gcc

wget https://github.com/operator-framework/operator-sdk/releases/download/v0.19.1/operator-sdk-v0.19.1-ppc64le-linux-gnu
chmod +x operator-sdk-v0.19.1-ppc64le-linux-gnu
mv operator-sdk-v0.19.1-ppc64le-linux-gnu /usr/local/bin/operator-sdk

GO_VERSION=1.19

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! BUILDER=docker make; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
