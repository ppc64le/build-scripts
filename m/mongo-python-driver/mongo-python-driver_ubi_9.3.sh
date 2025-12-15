#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package       : mongo-python-driver
# Version       : 4.13.0
# Source repo   : https://github.com/mongodb/mongo-python-driver
# Tested on     : UBI 9.3
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mongo-python-driver
PACKAGE_VERSION=${1:-4.13.0}
PACKAGE_URL=https://github.com/mongodb/mongo-python-driver
PACKAGE_DIR=mongo-python-driver

yum install -y git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ python3 python3-devel python3-pip
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
pip3 install pytest 'pytest-asyncio>=0.21.0'


git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Skipping specific test cases (e.g., test_container_metadata and test_metadata)
# These tests are currently excluded due to mismatched runtime/environment expectations
# (e.g., 'runtime': 'docker' being present in actual output but not in expected).
if ! pytest -k "not test_container_metadata and not test_metadata"; then
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
