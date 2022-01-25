# Package       : mongodb/mongo-go-driver
# Version       : v1.1.3
# Source repo   : https://github.com/mongodb/mongo-go-driver
# Tested on     : RHEL ubi 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Apurva Agrawal<Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/sh -e
PACKAGE_PATH=github.com/mongodb/
PACKAGE_NAME=mongo-go-driver
PACKAGE_VERSION=v1.1.3
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
mkdir -p $GOPATH/src/$PACKAGE_PATH
cd $GOPATH/src/$PACKAGE_PATH
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"
go mod init
go mod tidy
go mod vendor
if ! go build -v ./...; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        exit 1
fi

echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

#Test case is failing and getting error server selection error: server selection timeout, current topology: /
#{ Type: Unknown, Servers: [{ Addr: localhost:27017, Type: Unknown, Last error: connection() error occured during connection handshake: /
#dial tcp [::1]:27017: connect: connection refused }, ] }

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    exit 0
fi
