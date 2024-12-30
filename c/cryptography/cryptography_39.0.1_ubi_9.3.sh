#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : cryptography
# Version       : 39.0.1
# Source repo   : https://github.com/pyca/cryptography.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-check  : True
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
PACKAGE_VERSION=${1:-39.0.1}
PACKAGE_NAME=cryptography
PACKAGE_URL=https://github.com/pyca/cryptography

# Install dependencies and tools
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel python-devel

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install pytest and other dependencies
pip install pytest setuptools_rust cryptography_vectors==39.0.1 
pip install --upgrade pip setuptools cffi

# Install the package
if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME: Install fails -------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

pip install -r ci-constraints-requirements.txt
# Run tests
if ! pytest -n auto tests/conftest.py tests/test_cryptography_utils.py tests/test_rust_utils.py tests/test_fernet.py tests/test_warnings.py tests/hypothesis/ tests/bench/ tests/doubles.py; then
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
