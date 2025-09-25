#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : carbon-utils-position
# Version       : v1.1.1
# Source repo   : https://github.com/carbon-design-system/carbon-utils-position 
# Tested on     : UBI8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Nailusha Potnuru <pnailush@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Exit immediately if a command exits with a non-zero status.
set -e
PACKAGE_NAME=carbon-utils-position
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v1.1.1}
PACKAGE_URL=https://github.com/carbon-design-system/carbon-utils-position
yum -y update && yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake
npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn
mkdir -p output
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" >  output/version_tracker
        exit 0
fi
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
PACKAGE_VERSION=$(jq -r ".version" package.json)
# run the test command from test.sh
if ! npm install && npm audit fix && npm audit fix --force; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > output/install_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > output/version_tracker
        exit 1
fi
if ! npm test; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" >  output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" >  output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" >  output/version_tracker
        exit 0
fi

# Tests failing with "error:0308010C:digital envelope routines::unsupported" which is in parity with intel.
