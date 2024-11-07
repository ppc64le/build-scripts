#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : kiegroup/kie-cloud-operator
# Version       : 7.13.4-1
# Source repo   : https://github.com/kiegroup/kie-cloud-operator.git
# Tested on     : UBI:9.3
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>,Shubham Gupta <Shubham.Gupta43@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=kie-cloud-operator
PACKAGE_VERSION=${1:-7.13.4-1}
PACKAGE_URL=https://github.com/kiegroup/kie-cloud-operator.git

yum install -y git wget make gcc

wget https://github.com/operator-framework/operator-sdk/releases/download/v0.19.1/operator-sdk-v0.19.1-ppc64le-linux-gnu
chmod +x operator-sdk-v0.19.1-ppc64le-linux-gnu
mv operator-sdk-v0.19.1-ppc64le-linux-gnu /usr/local/bin/operator-sdk

#Install go 
wget https://go.dev/dl/go1.21.6.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.21.6.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! go build ./... ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION  | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! go test ./... ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION  | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi