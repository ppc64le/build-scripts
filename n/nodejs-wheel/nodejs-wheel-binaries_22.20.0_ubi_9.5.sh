#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : nodejs-wheel-binaries / nodejs-wheel
# Version       : 22.20.0
# Source repo   : https://github.com/njzjz/nodejs-wheel.git
# Tested on     : UBI:9.5
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Soham Badjate <soham.badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------



# Exit immediately if a command exits with a non-zero status
set -e
# Variables
PACKAGE_NAME=nodejs-wheel
PACKAGE_VERSION=${1:-v22.20.0}
PACKAGE_URL=https://github.com/njzjz/nodejs-wheel.git

# Install dependencies and tools.
yum update -y
yum install -y git gcc-c++  gcc make python3-pip
pip install --upgrade pip setuptools wheel

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! python3 tests/test_api.py ; then
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
