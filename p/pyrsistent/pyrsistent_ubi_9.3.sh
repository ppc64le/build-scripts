#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : pyrsistent
# Version       : 0.18.0
# Source repo   : https://github.com/tobgu/pyrsistent.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Robin Jain <robin.jain1@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_VERSION=${1:-v0.18.0}
PACKAGE_NAME=pyrsistent
PACKAGE_URL=https://github.com/tobgu/pyrsistent

# Install dependencies and tools
yum install -y git gcc gcc-c++ make wget xz-devel bzip2-devel openssl-devel zlib-devel libffi-devel python-devel

# Install pytest and hypothesis
pip install pytest hypothesis

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies from requirements.txt
pip install -r requirements.txt

# Install the package
if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME: Install fails -------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests
if ! pytest ; then
    echo "------------------$PACKAGE_NAME: Install success but test fails -----------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
