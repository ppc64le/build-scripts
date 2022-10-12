#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : github.com/nats-io/natscli
# Version       : main (v0.0.34-32-g2b0a465)
# Source repo   : https://github.com/nats-io/natscli
# Tested on     : UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shantanu Kadam <Shantanu.Kadam@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=natscli
PACKAGE_VERSION=${1:-main (v0.0.34-32-g2b0a465)}
PACKAGE_URL=https://github.com/nats-io/natscli
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#Install the required dependencies
yum -y update && yum install git gcc wget tar zip -y

GO_VERSION=1.18

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

#Clone the repository
echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME: clone failed-------------------------"
    exit 1
fi

cd $PACKAGE_NAME

go mod tidy

if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
fi 

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    exit 0
fi

