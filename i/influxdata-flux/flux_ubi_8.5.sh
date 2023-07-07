#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : flux
# Version       : v0.65.1
# Source repo   : https://github.com/influxdata/flux
# Tested on     : UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=flux
PACKAGE_VERSION=v0.65.1
PACKAGE_URL=https://github.com/influxdata/flux

#Install the required dependencies
yum -y update && yum install git gcc make wget tar zip -y

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

#Clone the repository
git clone $PACKAGE_URL

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go build; then
        echo "------------------$PACKAGE_NAME:install_fail---------------------"
        exit 0
fi

if ! go test; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        exit 0
fi