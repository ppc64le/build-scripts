#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jquery-ui
# Version       : 1.13.2
# Source repo   : https://github.com/jquery/jquery-ui
# Tested on     : UBI: 8.7
# Language      : JavaScript
# Travis-Check  : True
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
PACKAGE_NAME="jquery-ui"
PACKAGE_VERSION=${1:-"1.13.2"}
PACKAGE_URL=https://github.com/jquery/jquery-ui
NODE_VERSION=${NODE_VERSION:-12.19.1}
HOME_DIR=`pwd`


# Install dependencies
sudo yum install -y git fontconfig-devel.ppc64le wget curl libXcomposite libXcursor procps-ng java-11-openjdk-devel alsa-lib atk cups-libs gtk3 libXcursor libXdamage libXext libXi libXrandr libXScrnSaver libXtst pango 
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
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
#export PUPPETEER_SKIP_DOWNLOAD=true
#export PUPPETEER_EXECUTABLE_PATH=/chromium/chromium_84_0_4118_0/chrome
#PATH=$CHROME_BIN:$PATH

# Build package
if !(npm install && npm audit fix --force); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#Commeting test part as all tests in Leaflet require headless chrome browser for execution, which may not be accessible by the developer.
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