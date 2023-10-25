#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : arrow
# Version          : go/v10.0.1,go/v12.0.1
# Source repo      : https://github.com/apache/arrow
# Tested on        : UBI 8.7
# Language         : C++,Go
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
PACKAGE_VERSION=${1:-go/v12.0.1}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
GO_VERSION=`curl -s 'https://go.dev/VERSION?m=text' | grep ^go`

#Dependencies
yum install -y git sudo wget make gcc gcc-c++ cmake

wget "https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz"
rm -rf /usr/local/go 
tar -C /usr/local -xf $GO_VERSION.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH


go install gotest.tools/gotestsum@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1

if [ -d "$PACKAGE_NAME" ] ; then
rm -rf $PACKAGE_NAME
echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
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

# Build Arrow C++ library
mkdir cpp/build
cd cpp/build
cmake .. \
  -DARROW_WITH_SNAPPY=ON \
  -DARROW_WITH_ZLIB=ON \
  -DARROW_WITH_LZ4=ON \
  -DARROW_WITH_ZSTD=ON \
  -DARROW_PARQUET=ON \
  -DARROW_CSV=ON \
  -DARROW_DATASET=ON \
  -DARROW_BUILD_TESTS=OFF \
  -DARROW_BUILD_UTILITIES=OFF \
  -DARROW_BUILD_SHARED=ON \
  -DARROW_PYTHON=ON \
  -DPython3_EXECUTABLE=/usr/bin/python3 \
  -DARROW_JEMALLOC=OFF \
  -DCMAKE_BUILD_TYPE=Release
make -j4
sudo make install

# Build Arrow Go bindings
cd ../../go
go mod tidy

if ! go build -tags arrow -v ./... ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! go test -tags arrow -v ./... ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

