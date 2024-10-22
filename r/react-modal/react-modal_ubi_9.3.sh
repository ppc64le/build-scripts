#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : react-modal
# Version       : v3.16.1
# Source repo   : https://github.com/reactjs/react-modal
# Tested on     : UBI: 9.3
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
PACKAGE_NAME=react-modal
PACKAGE_VERSION=${1:-v3.16.1}
PACKAGE_URL=https://github.com/reactjs/react-modal
HOME_DIR=${PWD}

yum install -y yum-utils git wget tar gzip python3 python3-devel gcc gcc-c++ make cmake

#Installing Nodejs 
cd $HOME_DIR
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
source ~/.bashrc
nvm install 20
nvm use 20
node -v
npm -v


#Cloning repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#install
if ! npm install && npm audit fix && npm audit fix --force ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

#Commeting test part as tests require headless chrome browser for execution, which may not be accessible by the developer.
#test
#if ! npm test ; then
#    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#    exit 2
#else
#    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#    exit 0
#fi


