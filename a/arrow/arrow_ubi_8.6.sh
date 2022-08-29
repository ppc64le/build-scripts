#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: arrow
# Version	: v0.0.0-20191024131854-af6fa24be0db
# Source repo	: https://github.com/apache/arrow
# Tested on	: UBI 8.6
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=arrow
PACKAGE_VERSION=${1:-v0.0.0-20191024131854-af6fa24be0db}
PACKAGE_URL=https://github.com/apache/arrow
CURDIR="$(pwd)"
yum install -y git wget gcc-c++ openssl-devel golang tar

# set GOPATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

#Install arrow
go get github.com/apache/arrow/go/$PACKAGE_NAME@$PACKAGE_VERSION

#Add testcase patches
mkdir -p $CURDIR/go_sys
cd $CURDIR/go_sys
git clone https://github.com/golang/sys.git
cd sys
git checkout 20be8e55dc7b4b7a1b1660728164a8509d8c9209
cp cpu/cpu_linux.go $HOME/go/pkg/mod/github.com/apache/arrow/go/$PACKAGE_NAME@$PACKAGE_VERSION/internal/cpu/
cp cpu/cpu_ppc64x.go $HOME/go/pkg/mod/github.com/apache/arrow/go/$PACKAGE_NAME@$PACKAGE_VERSION/internal/cpu/

cd $HOME/go/pkg/mod/github.com/apache/arrow/go/$PACKAGE_NAME@$PACKAGE_VERSION/ 
sed -i '9s/cacheLineSize/CacheLineSize/' internal/cpu/cpu_ppc64x.go
sed -i '35,49d' internal/cpu/cpu_test.go
sed -i '38s/f.sum/sum_float64_go/' math/float64.go
sed -i '38s/f.sum/sum_uint64_go/' math/uint64.go
sed -i '38s/f.sum/sum_int64_go/' math/int64.go

go mod tidy

#Run tests
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