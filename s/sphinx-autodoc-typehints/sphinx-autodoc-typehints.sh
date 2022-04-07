#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : sphinx-autodoc-typehints
# Version       : 1.12.0
# Source repo   : https://github.com/tox-dev/sphinx-autodoc-typehints
# Tested on	: UBI 8.5
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer	: Sandeep Yadav <Sandeep.Yadav10@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=sphinx-autodoc-typehints
PACKAGE_VERSION=1.12.0
PACKAGE_URL=https://github.com/tox-dev/sphinx-autodoc-typehints
PACKAGE_FOLDER=sphinx-autodoc-typehints

#To install the dependencies.
yum install -y git  python3 python3-devel make gcc-c++ rust-toolset openssl openssl-devel libffi libffi-devel 

echo "Cloning pacakge $PACKAGE_URL"
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! python3 setup.py install; then
         exit 0
fi

if ! python3 setup.py test; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails" 
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi
