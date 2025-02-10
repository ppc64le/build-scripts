#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ml_dtypes
# Version          : 0.2.0
# Source repo      : https://github.com/jax-ml/ml_dtypes.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=ml_dtypes
PACKAGE_VERSION=${1:-v0.2.0}
PACKAGE_URL=https://github.com/jax-ml/ml_dtypes.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make cmake wget openssl-devel bzip2 bzip2-devel libffi-devel zlib-devel python3-devel python3-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule init
git submodule update

#build eigen
wget https://gitlab.com/libeigen/eigen/-/archive/master/eigen-master.tar.bz2
tar -xvjf eigen-master.tar.bz2
cd eigen-master
mkdir build
cd build
cmake ..
make install
cd /ml_dtypes

# Install additional dependencies
pip install wheel build pytest absl-py pybind11 'numpy<2' setuptools

#install
export CXXFLAGS="-I/usr/local/include/eigen3"
export CFLAGS="-I/usr/local/include/eigen3"
if ! pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests
if ! pytest; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
