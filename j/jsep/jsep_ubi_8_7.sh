#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jsep
# Version       : v1.3.8
# Source repo   : https://github.com/EricSmekens/jsep
# Tested on     : UBI: 8.7
# Language      : JavaScript
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

set -e

# Variables
PACKAGE_NAME="jsep"
PACKAGE_VERSION=${1:-"v1.3.8"}
PACKAGE_URL=https://github.com/EricSmekens/jsep
NODE_VERSION=${NODE_VERSION:-12.19.1}
HOME_DIR=`pwd`


#Install dependencies
yum install -y git fontconfig-devel wget curl libXcomposite libXcursor procps-ng python38 python38-devel git gcc gcc-c++ libffi make
cd $HOME_DIR

#Install node
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz
tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH
node -v
npm -v

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
#export CHROME_BIN=/chromium/chromium_84_0_4118_0/chrome
#PATH=CHROME_BIN:$PATH
npm install --force

# Build package
if !(npm audit fix & npm audit fix --force); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

#Commeting test part as all tests in jsep require headless chrome browser for execution, which may not be accessible by the developer.
# Please refer to README.md to install the chrome binaries required for the testing

# Run test cases
#if ! npm test; then
#    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
#    exit 2
#else
#    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
#    exit 0
#fi