#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : argon2-cffi-bindings
# Version           : 26.1.0
# Source repo       : https://github.com/hynek/argon2-cffi-bindings
# Tested on         : UBI:9.3
# Language          : Python
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Variables
PACKAGE_NAME=argon2-cffi-bindings
PACKAGE_VERSION=${1:-26.1.0}
PACKAGE_URL=https://github.com/hynek/argon2-cffi-bindings
PACKAGE_DIR=./argon2-cffi-bindings
CURRENT_DIR="${PWD}"

#install dependencies (26.1.0 requires Python >= 3.10)
yum install -y wget git make python3.12 python3.12-devel python3.12-pip openssl-devel cmake unzip

yum install -y gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran

# Activate GCC Toolset 13
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

#build and install libargon2
git clone https://github.com/P-H-C/phc-winner-argon2.git
cd phc-winner-argon2
make
make install
cd $CURRENT_DIR

#clone and build argon2-cffi-bindings
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# 26.1.0 builds with scikit-build-core + CMake (pulled in via build isolation)
python3.12 -m pip install tox wheel build argon2-cffi scikit-build-core setuptools-scm

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
if ! tox -e py312 ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
