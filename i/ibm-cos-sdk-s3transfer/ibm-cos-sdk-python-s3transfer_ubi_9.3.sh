#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ibm-cos-sdk-s3transfer
# Version       : 2.14.0
# Source repo   : https://github.com/IBM/ibm-cos-sdk-python-s3transfer
# Tested on	: UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ibm-cos-sdk-s3transfer
PACKAGE_VERSION=${1:-2.14.0}
PACKAGE_URL=https://github.com/IBM/ibm-cos-sdk-python-s3transfer
PACKAGE_DIR=ibm-cos-sdk-python-s3transfer

# Install dependencies
yum install -y git gcc gcc-c++ make wget sudo openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

#install necessary Python packages
pip install wheel pytest tox nox


#Install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Skipping test part as test is failing due to a missing file requirements-dev-lock.txt. This is in parity with Intel.
# There is already an issue open for this: https://github.com/IBM/ibm-cos-sdk-python-core/issues/25
#if !(python3 -m tox -e py3); then
#    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#    exit 2
#else
#    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#    exit 0
#fi
