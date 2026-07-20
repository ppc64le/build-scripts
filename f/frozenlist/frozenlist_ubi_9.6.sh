#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : frozenlist
# Version       : v1.3.3
# Source repo   : https://github.com/aio-libs/frozenlist.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
#variables
PACKAGE_NAME=frozenlist
PACKAGE_VERSION=${1:-v1.3.3}
PACKAGE_URL=https://github.com/aio-libs/frozenlist.git
PACKAGE_DIR=frozenlist

# Install dependencies and tools.
yum install -y wget gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran git make python3-devel python3-pip openssl-devel

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Fix Python 3.13 compatibility
sed -i 's/SKIP_METHODS = {/SKIP_METHODS = {\n        "__static_attributes__",\n        "__firstlineno__",/' tests/test_frozenlist.py

#install cython,pytest
pip3 install cython pytest

cython frozenlist/_frozenlist.pyx

#install
if ! (pip3 install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest -o addopts=""; then
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
