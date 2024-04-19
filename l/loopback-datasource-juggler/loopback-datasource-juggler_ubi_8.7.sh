#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : loopback-datasource-juggler
# Version       : master
# Source repo   : https://github.com/loopbackio/loopback-datasource-juggler
# Tested on     : UBI: 8.7
# Language      : JavaScript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=loopback-datasource-juggler
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/loopbackio/loopback-datasource-juggler

yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless sudo  librsvg2 libjpeg-turbo libjpeg-turbo-devel giflib

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin
export NODE_VERSION=v18.19.0

#install node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash 
source "$HOME"/.bashrc 
echo "installing nodejs $NODE_VERSION" 
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
source "$HOME"/.bashrc 
npm ci --ignore-scripts

if ! npm run build ;  then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! npm test --ignore-scripts ; then
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
