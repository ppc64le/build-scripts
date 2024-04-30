#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : mongo-go-driver
# Version       : v1.15.0
# Source repo   : https://github.com/mongodb/mongo-go-driver
# Tested on     : UBI: 9.3
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_PATH=github.com/mongodb/
PACKAGE_NAME=mongo-go-driver
PACKAGE_VERSION=v1.15.0
PACKAGE_URL=https://github.com/mongodb/mongo-go-driver

# Install dependencies
yum install -y make git wget gcc

# Download and install go
wget https://golang.org/dl/go1.17.5.linux-ppc64le.tar.gz
tar -xzf go1.17.5.linux-ppc64le.tar.gz
rm -rf go1.17.5.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

# Clone the repo and checkout submodules
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install mongodb
yum install https://repo.mongodb.com/yum/redhat/8/mongodb-enterprise/7.0/ppc64le/RPMS/mongodb-enterprise-server-7.0.8-1.el8.ppc64le.rpm

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"
go mod init
go mod tidy
go mod vendor

if ! go build -v ./... ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"
cd x/mongo/driver/topology/
if ! go test -v ./... ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi