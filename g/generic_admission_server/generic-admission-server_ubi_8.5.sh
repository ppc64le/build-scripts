#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : generic-admission-server
# Version       : v1.14.0
# Source repo   : https://github.com/openshift/generic-admission-server
# Tested on     : UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <shreya.kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=generic-admission-server
PACKAGE_VERSION=${1:-v1.14.0}
PACKAGE_URL=https://github.com/openshift/generic-admission-server.git

#Install the required dependencies
yum -y update && yum install git gcc make wget tar zip -y
GO_VERSION=1.10

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/usr/bin/go/

#Setup working directory
mkdir -p $GOPATH/src/github.com/openshift && cd $GOPATH/src/github.com/openshift

#Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init github.com/openshift/generic-admission-server.git
go mod tidy
go mod vendor

if ! make build; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
fi
if ! go test ./... ; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    exit 0
fi