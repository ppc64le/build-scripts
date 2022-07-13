#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : py-robo
# Version       : latest
# Source repo   : https://github.com/heavenshell/py-robo
# Tested on     : UBI 8.5
# Language      : Python
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=py-robo
PACKAGE_VERSION=latest
PACKAGE_URL=https://github.com/heavenshell/py-robo.git

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++

yum install python2 -y
pip3 install dnspython
pip3 install blinker
pip3 install sleekxmpp
pip3 install pyasn1
pip3 install pyasn1_modules
pip3 install flake8

git clone $PACKAGE_URL

cd $PACKAGE_NAME

pip3 install -r requirements.txt

if ! (python3 setup.py test) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home
                        exit 0
                fi

