#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : 1.23.5
# Source repo :  https://github.com/numpy/numpy
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e
# Variables
PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v1.23.5}
PACKAGE_URL=https://github.com/numpy/numpy

# Install dependencies and tools.
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake
pip3 install hypothesis==6.115.5 typing_extensions meson==1.6.0 ninja==1.11.1.1 pytest==7.4.2  'Cython<3.0,>=0.29.30' setuptools==59.2.0 wheel==0.37.0

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

#install
#Editable installs use PEP517 isolation.
if ! pip3 install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
#test
sed -i 's/suppress_health_check=hypothesis\.HealthCheck\.all()/suppress_health_check=list(hypothesis.HealthCheck)/' numpy/conftest.py
if ! python3 runtests.py; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
