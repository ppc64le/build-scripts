#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : configbump
# Version       : v0.1.5
# Source repo   : https://github.com/che-incubator/configbump
# Tested on     : UBI 8.5
# Language      : GO
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

PACKAGE_NAME=configbump
PACKAGE_VERSION=${1:-0.1.5}
PACKAGE_URL=https://github.com/che-incubator/configbump

yum install -y git gcc wget make

GO_VERSION=${GO_VERSION:-1.13}

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! go mod download; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

if ! go test -v  ./...; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi