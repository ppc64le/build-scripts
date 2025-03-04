#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numexpr
# Version       : v2.10.2
# Source repo   : https://github.com/pydata/numexpr.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=numexpr
PACKAGE_VERSION=${1:-v2.10.2}
PACKAGE_URL=https://github.com/pydata/numexpr.git
PACKAGE_DIR=./numexpr

# Install dependencies and tools.
yum install -y git gcc gcc-c++ make wget openssl-devel python-devel python-pip bzip2-devel libffi-devel wget xz zlib-devel cmake openblas-devel

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install pytest
pip install pytest

pip install numpy==2.0.2
pip install -e .

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
