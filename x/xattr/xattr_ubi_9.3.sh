#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xattr
# Version       : v1.1.4
# Source repo   : https://github.com/xattr/xattr
# Tested on     : UBI 9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Manya Rusiya <Manya.Rusiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=xattr
PACKAGE_VERSION=${1:-v1.1.4}
PACKAGE_URL=https://github.com/xattr/xattr
PACKAGE_DIR=xattr

# Install Dependencies 
yum install -y git python3.12 python3.12-devel python3.12-pip \
    gcc gcc-c++ libffi-devel

# Clone Repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Setup Build Environment
python3.12 -m pip install --upgrade pip setuptools wheel cffi

# Install Test Dependencies
python3.12 -m pip install pytest hypothesis tox

# ------------------ Install ------------------
if ! python3.12 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# ------------------ Tests ------------------
if ! tox -e py312; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
