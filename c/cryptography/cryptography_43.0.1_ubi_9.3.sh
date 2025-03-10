#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : cryptography
# Version           : 44.0.0
# Source repo       : https://github.com/pyca/cryptography.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=cryptography
PACKAGE_VERSION=${1:-44.0.0}
PACKAGE_URL=https://github.com/pyca/cryptography.git
PACKAGE_DIR=cryptography

# Install dependencies
yum install -y git gcc gcc-toolset-13 gcc-c++ make sudo wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip rust cargo

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#cryptography.exceptions.UnsupportedAlgorithm: sha1 is not supported by this backend for RSA signing. so setting this export
export OPENSSL_ENABLE_SHA1_SIGNATURES=1
#install necessary Python packages
pip install wheel pytest tox nox cryptography_vectors==44.0.0 pytest-benchmark pretend certifi  pytest-cov pytest-xdist

if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
