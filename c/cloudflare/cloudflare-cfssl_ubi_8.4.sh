#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : cloudflare/cfssl
# Version       : v1.6.1
# Source repo   : https://github.com/cloudflare/cfssl
# Tested on     : RHEL ubi 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Apurva Agrawal <Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#build script is failing because of some certification failure in test case: the error is/
#2022/02/17 10:39:13 [INFO] bundling certificate for
#    bundler_test.go:923: {"code":1211,"message":"x509: certificate has expired or is not yet valid: current time 2022-02-17T10:39:13Z is after 2021-09-21T02:06:00Z"}
#Also check on INTEL same test case failure is coming there as well.
#Raise the issue to community as well https://github.com/cloudflare/cfssl/issues/1227

PACKAGE_PATH=github.com/cloudflare/
PACKAGE_NAME=cfssl
PACKAGE_VERSION=${1:-v1.6.1}
PACKAGE_URL=https://github.com/cloudflare/cfssl

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
if ! make all; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        exit 1
fi

echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"
chmod +x test.sh
if ! ./test.sh; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        exit 0
fi
