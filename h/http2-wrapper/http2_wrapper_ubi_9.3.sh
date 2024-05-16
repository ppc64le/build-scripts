#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : http2-wrapper 
# Version       : v2.2.1
# Source repo   : https://github.com/szmarczak/http2-wrapper.git
# Tested on     : UBI:9.3
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Mohit Pawar <mohit.pawar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

WORK_DIR=`pwd`

PACKAGE_NAME=http2-wrapper
PACKAGE_VERSION=${1:-v2.2.1}
PACKAGE_URL=https://github.com/szmarczak/http2-wrapper.git

export NODE_VERSION=${NODE_VERSION:-16}
yum install -y python3 python3-devel git gcc gcc-c++ libffi make

#Installing nvm 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm i --package-lock-only
npm install yarn -g
yarn --ignore-engines

#if ! npm install && npm audit fix && npm audit fix --force; then
if ! yarn install --ignore-certificate-errors ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    eho "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! yarn test --ignore-certificate-errors; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
