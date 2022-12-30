#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : badger
# Version       : v1.6.2
# Source repo   : https://github.com/dgraph-io/badger
# Tested on     : ubi 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Patchari <haritha.patchari@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------



PACKAGE_NAME="github.com/dgraph-io/badger"
PACKAGE_VERSION=${1:-"v1.6.2"}
PACKAGE_URL="https://github.com/dgraph-io/badger"


echo "installing dependencies from system repo..."
yum install -y gcc-c++ make wget git

#installing golang

wget https://golang.org/dl/go1.13.linux-ppc64le.tar.gz
tar -C /bin -xf go1.13.linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/goi


mkdir -p $GOPATH/src && cd $GOPATH/src
git clone $PACKAGE_URL
cd badger
git checkout $PACKAGE_VERSION

go mod tidy
go install

if ! go build; then
        echo "............................$PACKAGE_NAME:build_fails ......................"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi


if ! go test; then
        echo "............................$PACKAGE_NAME:test_fails ......................."
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | Github | Fail | Test_Fails"
        exit 1

else
        echo "............................$PACKAGE_NAME:test_success ......................."
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME |Github | Pass | Test_Success"
        exit 0
fi
