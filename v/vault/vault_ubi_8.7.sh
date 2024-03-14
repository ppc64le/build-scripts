#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vault
# Version       : v1.11.2, v1.11.3, v1.12.3,v1.13.1,v1.14.0
# Source repo   : https://github.com/hashicorp/vault
# Tested on     : UBI 8.7
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vault
PACKAGE_VERSION=${1:-v1.15.6}
GO_VERSION=${GO_VERSION:-1.21.7}
PACKAGE_URL=https://github.com/hashicorp/vault

WORKDIR=`pwd`

yum install -y openssl sudo make git gcc wget

cd $WORKDIR
 #install go
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz 
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go 
export GOPATH=$HOME 
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#Clone and build the source
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! make ; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! make testrace TEST=./vault ; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
