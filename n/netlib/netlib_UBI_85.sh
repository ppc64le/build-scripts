#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : netlib
# Version       : v0.16.0
# Source repo   : https://github.com/gonum/netlib.git
# Tested on     : UBI 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=netlib
PACKAGE_VERSION=v0.16.0
PACKAGE_URL=https://github.com/gonum/netlib.git

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++ gplang


go get -d gonum.org/v1/netlib/...

export CGO_LDFLAGS="-L/opt/OpenBLAS/lib -lopenblas"
go install gonum.org/v1/netlib/blas/netlib

export CGO_LDFLAGS="-L/opt/OpenBLAS/lib -lopenblas"
go install gonum.org/v1/netlib/lapack/netlib

git clone https://github.com/xianyi/OpenBLAS
cd OpenBLAS/
make
make install


export CGO_LDFLAGS="-L/root/go/pkg/mod/gonum.org/v1/netlib@v0.0.0-20220323200511-14de99971b2d/OpenBLAS -lopenblas"
go install gonum.org/v1/netlib/blas/netlib
go install gonum.org/v1/netlib/lapack/netlib


export PATH=$GOPATH/bin:$PATH

rm -rf $PACKAGE_NAME

cd /root/go/pkg/mod/gonum.org/v1/netlib@v0.0.0-20220323200511-14de99971b2d/

if ! (go test -a -v ./...) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_fails
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
                        exit 0
                fi

