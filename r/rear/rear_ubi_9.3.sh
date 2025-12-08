#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : rear
# Version          : rear-2.7
# Source repo      : https://github.com/rear/rear
# Tested on	       : UBI: 9.3
# Language         : Shell
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer	   : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=rear
PACKAGE_VERSION=${1:-rear-2.7}
PACKAGE_URL=https://github.com/rear/rear

yum update -y
yum install git make -y

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

if ! make install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! rear -V; then
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
