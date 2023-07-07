#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : shepherd
# Version       : v8.3.1
# Source repo   : https://github.com/shipshapecode/shepherd.git
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

PACKAGE_NAME=shepherd
PACKAGE_VERSION=v8.3.1
PACKAGE_URL=https://github.com/shipshapecode/shepherd.git

yum install java java-devel yum-utils nodejs nodejs-devel nodejs-packaging npm wget git -y

npm install -g n

n stable
npm install yarn



export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.345.b01-1.el8_6.ppc64le/bin/



rm -rf $PACKAGE_NAME

git clone $PACKAGE_URL


cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! (yarn install && yarn test) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi


