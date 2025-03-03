#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pillow
# Version       : 11.0.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:9.3
# Language      : Python, C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pillow
PACKAGE_DIR=Pillow
PACKAGE_VERSION=${1:-11.0.0}
PACKAGE_URL=https://github.com/python-pillow/Pillow/

# install core dependencies
yum install -y python3 python3-pip python3-devel gcc git gcc gcc-c++ gcc-toolset-13 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH


# install pillow's minimum dependencies
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel openblas

# install build tools for wheel generation
pip install --upgrade pip setuptools wheel pytest numpy

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest; then
        echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0

fi
