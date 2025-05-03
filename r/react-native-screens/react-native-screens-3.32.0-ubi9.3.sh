#!/bin/bash -ex
# --------------------------------------------------------------------------------------------
#
# Package       : react-native-screens
# Version       : 3.32.0
# Source repo   : https://github.com/software-mansion/react-native-screens.git
# Tested on     : UBI 9.3 (docker)
# Language      : TypeScript,Kotlin,Objective-C++,C++,JavaScript,Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# --------------------------------------------------------------------------------------------

# Install RHEL dependencies
yum install -y git java-17-openjdk-devel

# Set variables
WDIR=$(pwd)
PACKAGE_NAME=react-native-screens
PACKAGE_URL=https://github.com/software-mansion/react-native-screens.git
PACKAGE_VERSION=${1:-3.32.0}

export NODE_VERSION=${NODE_VERSION:-18}
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

#Install yarn
npm install -g yarn
yarn -v

# Clone react-native-screens repository
cd $WDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Install
if ! yarn install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Build/Prepare
if ! yarn prepare; then
    echo "------------------$PACKAGE_NAME:prepare_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  prepare_Fails"
    exit 1
fi

if ! yarn test:unit; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_prepare_&_test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_prepare_and_Test_Success"
    exit 0
fi
