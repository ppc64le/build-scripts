#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : 1.26.0
# Source repo   : https://github.com/numpy/numpy
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
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
PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v1.26.0}
PACKAGE_URL=https://github.com/numpy/numpy

# Install dependencies and tools.
yum install -y git wget gcc gcc-c++ python python-devel python-pip openssl-devel cmake openblas-devel
pip install tox Cython pytest==7.4.2 hypothesis wheel meson ninja


#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init


#install
if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! python3 runtests.py; then
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
