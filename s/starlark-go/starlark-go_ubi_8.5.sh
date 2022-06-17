#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : starlark-go
# Version       : d1966c6
# Source repo   : https://github.com/google/starlark-go
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathsala .<vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=starlark-go
PACKAGE_VERSION=${1:-d1966c6}
PACKAGE_URL=https://github.com/google/starlark-go

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
PATCH_FILE=$SCRIPT_DIR/starlark.patch

yum install -y git  make gcc diffutils wget patch

wget https://golang.org/dl/go1.17.linux-ppc64le.tar.gz
rm -rf /home/go && tar -C /home -xzf go1.17.linux-ppc64le.tar.gz
rm -f go1.17.linux-ppc64le.tar.gz
export GOPATH=/home/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export  GO111MODULE=on

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# edit source code
patch -u --ignore-whitespace starlarktest/starlarktest.go -i $PATCH_FILE

if ! go build -v ./...; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

if ! go test -a -v ./... && internal/test.sh; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

