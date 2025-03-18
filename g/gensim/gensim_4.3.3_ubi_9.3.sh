#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : gensim
# Version       : 4.3.3
# Source repo   : https://github.com/RaRe-Technologies/gensim
# Tested on : UBI 9.3
# Language : Python, C, Fortran, C++, Cython, Meson
# Travis-Check : True
# Script License: Apache License, Version 2 or later
# Maintainer : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
#variables
PACKAGE_NAME=gensim
PACKAGE_VERSION=${1:-4.3.3}
PACKAGE_URL=https://github.com/RaRe-Technologies/gensim
PACKAGE_DIR=gensim

# Install dependencies
echo "Installing system dependencies..."
yum install -y git gcc gcc-c++ gcc-fortran wget python3.12-devel python3.12 make openblas openblas-devel ninja-build

echo "Upgrading pip..."
python3.12 -m pip install -U pip

echo "Installing required Python packages..."
python3.12 -m pip install requests ruamel-yaml 'meson-python<0.13.0,>=0.11.0'  setuptools==76.0.0 numpy==2.0.2 scipy==1.15.2 Cython==3.0.12 nbformat pytest testfixtures mock nbconvert

# Clone the repository
echo "Cloning the repository from $PACKAGE_URL..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
echo "Checking out version $PACKAGE_VERSION..."
git checkout $PACKAGE_VERSION

echo "Building the package using setup.py..."
#Compiled extensions are unavailable.
python3.12 -m pip install scipy
python3.12 setup.py build_ext --inplace


# Build package
echo "Attempting to install the package..."
if !(python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
python3.12 -m pip install gensim==4.3.3
echo "Running test cases with pytest..."
if !(pytest); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
