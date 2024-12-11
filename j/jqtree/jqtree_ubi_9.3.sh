#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : jqTree
# Version          : 1.8.7
# Source repo      : https://github.com/mbraak/jqTree.git
# Tested on        : UBI:9.3
# Language         : JavaScript
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=jqTree
PACKAGE_VERSION=${1:-1.8.7}
PACKAGE_URL=https://github.com/mbraak/jqTree.git

export NODE_VERSION=${NODE_VERSION:-20}

#install dependencies
yum install -y python3.11 python3.11-devel git gcc gcc-c++ libffi make

#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

npm install -g pnpm

git clone $PACKAGE_URL
cd $PACKAGE_NAME 
git checkout $PACKAGE_VERSION

#install
if ! pnpm install ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pnpm run jest ; then
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
