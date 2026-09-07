#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pywt
# Version          : v1.9.0
# Source repo      : https://github.com/PyWavelets/pywt
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pywt
PACKAGE_VERSION=${1:-v1.9.0}
PACKAGE_URL=https://github.com/PyWavelets/pywt

# Install dependencies
yum install -y gcc gcc-c++ make libtool cmake git wget xz python3.14 python3.14-devel python3.14-pip zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel libjpeg-turbo-devel

export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Python dependencies
python3.14 -m pip install numpy==2.5.0 pillow "pytest<9" cython

# Install package
if ! python3.14 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd demo

# Run tests
# Ignore NumPy 2.5.0 deprecation warnings caused by deprecated APIs in
# the PyWavelets 1.9.0 test suite.
if ! pytest --pyargs pywt -W ignore::DeprecationWarning; then
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