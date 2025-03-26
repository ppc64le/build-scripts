#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : mypy_extensions
# Version       : 0.4.3
# Source repo   : https://github.com/python/mypy_extensions.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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
PACKAGE_VERSION=${1:-0.4.3}
PACKAGE_NAME=mypy_extensions
PACKAGE_URL=https://github.com/python/mypy_extensions

# Install dependencies and tools
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo python3-devel python3-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME 
git checkout $PACKAGE_VERSION

# Install the package
if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME: Install fails -------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Install tox
pip3 install tox

# Run tests
if ! tox -e py39; then
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
