#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : eslint
# Version          : go/v10.0.1
# Source repo      : https://github.com/apache/arrow
# Tested on        : UBI 8.5
# Language         : Go
# Travis-Check     : True 
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=arrow
PACKAGE_URL=https://github.com/apache/arrow.git
PACKAGE_VERSION=go/v10.0.1
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#Dependencies
dnf install -y git wget make gcc gcc-c++
wget https://go.dev/dl/go1.19.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.19.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

go install gotest.tools/gotestsum@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1

if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git submodule init
git submodule update
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"

go install honnef.co/go/tools/cmd/staticcheck@latest
cd go

go mod tidy

if ! go test ./... ; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
        exit 0
fi

