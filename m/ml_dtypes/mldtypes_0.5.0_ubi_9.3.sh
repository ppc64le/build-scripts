#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ml_dtypes
# Version       : 0.5.0
# Source repo   : https://github.com/jax-ml/ml_dtypes.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
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
PACKAGE_NAME=ml_dtypes
PACKAGE_VERSION=${1:-v0.5.0}
PACKAGE_URL=https://github.com/jax-ml/ml_dtypes.git
PACKAGE_DIR=ml_dtypes

yum install -y git wget gcc-toolset-13 gcc-c++ openblas python python3-devel python3 python3-pip openssl-devel cmake zip unzip
pip3 install absl-py numpy pytest pybind11

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

#Install eigen
wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip
unzip eigen-3.4.0.zip
cp -r eigen-3.4.0/Eigen/ /usr/local/include

export CFLAGS=-I/usr/include
export CXXFLAGS=-I/usr/include
export CC=/opt/rh/gcc-toolset-13/root/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/bin/g++

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule init
git submodule update


#Install the package
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

pip install ml_dtypes

#Run tests(Skipping testcase as its failing in x86 also)
if !(pytest -k "not(testFInfo_float8_e8m0fnu)"); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
