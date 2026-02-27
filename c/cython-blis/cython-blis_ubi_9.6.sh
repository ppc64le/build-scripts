#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cython-blis
# Version          : release-v1.3.0
# Source repo      : https://github.com/explosion/cython-blis.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
# Variables
PACKAGE_NAME=cython-blis
PACKAGE_VERSION=${1:-release-v1.3.0}
PACKAGE_URL=https://github.com/explosion/cython-blis.git
CURRENT_DIR="${PWD}"

echo "Installing system dependencies..."

yum install -y git gcc gcc-c++ make \
    python3 python3-devel python3-pip \
    openblas-devel

echo "Upgrading pip tooling..."
python3 -m pip install --upgrade pip setuptools wheel

echo "Cloning repository..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Installing build dependencies..."
python3 -m pip install cython numpy pytest hypothesis

echo "Setting compiler environment..."

# Remove any broken compiler references
unset CC
unset CXX

# Force system compiler
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

# Ensure Power9 build
export BLIS_ARCH=power9
export OPENBLAS_HOME=/usr

# Clean old artifacts if present
rm -rf build
rm -rf *.egg-info

echo "Building package..."

if ! python3 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Build_Fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

echo "Running tests from installed package..."

# Move out of source directory to avoid shadowing
cd $CURRENT_DIR

if ! python3 -m pytest -v --pyargs blis ; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Build_and_Test_Success"
    exit 0
fi