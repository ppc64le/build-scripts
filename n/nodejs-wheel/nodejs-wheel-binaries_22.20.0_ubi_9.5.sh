#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : nodejs-wheel-binaries / nodejs-wheel
# Version       : 24.19.0
# Source repo   : https://github.com/njzjz/nodejs-wheel.git
# Tested on     : UBI:9.5
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Soham Badjate <soham.badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
PACKAGE_NAME=nodejs-wheel
PACKAGE_VERSION=${1:-v24.19.0}
PACKAGE_URL=https://github.com/njzjz/nodejs-wheel.git

# Install dependencies and tools.
yum update -y
yum install -y git make cmake python3-pip python3-devel gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-binutils

# Enable GCC toolset 13
source /opt/rh/gcc-toolset-13/enable
export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

N_CORES=$(nproc)
export CMAKE_BUILD_PARALLEL_LEVEL=${N_CORES}
export MAKEFLAGS="-j${N_CORES}"

pip install --upgrade pip setuptools wheel scikit-build-core setuptools_scm ninja

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION || git checkout v$PACKAGE_VERSION

# Ensure CMake uses all available cores for building Node.js
sed -i "s/ProcessorCount(N)/set(N ${N_CORES})/" CMakeLists.txt
sed -i "s/make -j\${N}/make -j${N_CORES}/" CMakeLists.txt

# Install
if ! pip install --no-build-isolation -v . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test
if ! python3 tests/test_api.py ; then
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
