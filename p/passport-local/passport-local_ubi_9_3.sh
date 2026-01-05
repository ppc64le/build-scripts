#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : passport-local
# Version       : v1.0.0
# Source repo   : https://github.com/jaredhanson/passport-local
# Tested on     : UBI: 9.3
# Language      : TypeScript
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME="passport-local"
PACKAGE_VERSION=${1:-"v1.0.0"}
PACKAGE_URL=https://github.com/jaredhanson/passport-local
NODE_VERSION=${NODE_VERSION:-"18.17.0"}
HOME_DIR=${PWD}
export NODE_OPTIONS="--dns-result-order=ipv4first"

#Install dependencies
#yum -y update
yum install -y yum-utils wget git gcc gcc-c++ make python3-devel

#Installing node
cd $HOME_DIR
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz
tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH
node -v

# Clone the repository
cd $HOME_DIR
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install -g mocha


#Build 
if ! npm install; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#Test 
if ! mocha --reporter spec --require test/bootstrap/node test/*.test.js; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  both_build_and_test_success"
    exit 0
fi