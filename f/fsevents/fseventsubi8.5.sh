#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : fsevents
# Version       : v2.2.0
# Source repo   : https://github.com/fsevents/fsevents.git
# Tested on     : UBI 8.5
# Language      : Node
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Ankit.Paraskar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=fsevents
PACKAGE_VERSION=v2.2.0
PACKAGE_URL=https://github.com/fsevents/fsevents.git

yum install yum-utils nodejs nodejs-devel nodejs-packaging npm wget -y


npm install -g n
n lts

npm i -g npm-upgrade

rm -rf $PACKAGE_NAME

git clone $PACKAGE_URL


cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! (npm install && npm audit fix && npm test) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi

