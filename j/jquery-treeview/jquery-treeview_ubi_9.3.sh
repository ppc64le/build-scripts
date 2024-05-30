#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jquery-treeview
# Version       : master
# Source repo   : https://github.com/jzaefferer/jquery-treeview
# Tested on     : UBI: 9.3
# Language      : Javascript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jquery-treeview
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/jzaefferer/jquery-treeview

yum install -y git nodejs npm
npm install -g bower

git clone $PACKAGE_URL
cd $PACKAGE_NAME 
git checkout $PACKAGE_VERSION

#NO TESTS PRESENT 

if ! bower install --allow-root ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
    exit 0
fi