#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : markbates/pkger
# Version       : v0.17.1
# Source repo   : https://github.com/markbates/pkger.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    :  Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# 
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/markbates/pkger
PACKAGE_VERSION=${1:-v0.17.1}
PACKAGE_URL=https://github.com/markbates/pkger.git

yum install -y gcc-c++ make wget

#install GO1.13
cd /opt && wget https://golang.org/dl/go1.13.linux-ppc64le.tar.gz && tar -C /bin -xf go1.13.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg
rm -rf go1.13.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

#Clone the Repo.
go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION
cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION

#Build and test the package.
go mod init pkger
go mod tidy
go install
go test
#Note: 1 test is failing related to Test_Walk
