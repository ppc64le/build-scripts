#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : gmpy2
# Version       : gmpy2-2.2.1
# Source repo   : https://github.com/aleaxit/gmpy.git
# Tested on     : UBI:10.1
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=gmpy2
PACKAGE_VERSION=${1:-v2.2.1}
PACKAGE_URL=https://github.com/aleaxit/gmpy.git
# Install dependencies and tools.
yum install -y wget gcc gcc-c++ gcc-gfortran git make  python3.12-devel  openssl-devel gmp-devel.ppc64le  mpfr-devel.ppc64le libmpc-devel.ppc64le

#clone repository 
git clone $PACKAGE_URL
cd  gmpy
git checkout $PACKAGE_VERSION

python3.12 -m pip install cython
python3.12 -m pip --verbose install --editable .[docs,tests]

#install
if ! (python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! python3.12 test_cython/runtests.py; then
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
