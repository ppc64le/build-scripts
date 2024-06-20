#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : sphinx-gallery
# Version       : latest
# Source repo   : https://pypi.io/packages/source/s/sphinx-gallery/sphinx-gallery-0.10.0.tar.gz
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

PACKAGE_NAME=sphinx-gallery
PACKAGE_VERSION=latest
PACKAGE_URL=https://pypi.io/packages/source/s/sphinx-gallery/sphinx-gallery-0.10.0.tar.gz

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++

yum install python2 -y


wget https://pypi.io/packages/source/s/sphinx-gallery/sphinx-gallery-0.10.0.tar.gz

tar -xvf sphinx-gallery-0.10.0.tar.gz


cd sphinx-gallery-0.10.0

pip3 install -r requirements.txt

pip3 install -e .

pip3 install pytest

if ! (python3 setup.py test) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi

