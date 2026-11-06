#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : murmurhash
# Version          : release-v1.0.16
# Source repo      : https://github.com/explosion/murmurhash
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=murmurhash
PACKAGE_VERSION=${1:-release-v1.0.16}
PACKAGE_URL=https://github.com/explosion/murmurhash
PACKAGE_DIR=murmurhash
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git make wget gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ python3.12 python3.12-devel python3.12-pip

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Build needs cython>=3.1
python3.12 -m pip install --upgrade pip setuptools wheel build pytest "cython>=3.1"

# Install package
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the installed package, not the source tree
cd $CURRENT_DIR
if ! python3.12 -m pytest -v --pyargs $PACKAGE_NAME ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Install_and_Test_Success"
    exit 0
fi
