#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : gensim
# Version       : 4.3.2
# Source repo   : https://github.com/RaRe-Technologies/gensim
# Tested on : UBI 9.3
# Language : Python, C, Fortran, C++, Cython, Meson
# Ci-Check : True
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

PACKAGE_NAME=gensim
PACKAGE_VERSION=${1:-4.3.2}
PACKAGE_URL=https://github.com/RaRe-Technologies/gensim
PACKAGE_DIR=gensim

# Install dependencies
echo "Installing system dependencies..."
yum install -y git gcc gcc-c++ gcc-fortran wget python3-devel python3 make openblas openblas-devel ninja-build

echo "Upgrading pip..."
python3 -m pip install -U pip

echo "Installing required Python packages..."
pip3 install oldest-supported-numpy "numpy>=1.21,<1.24" "scipy>=1.9,<1.12"
pip3 install requests ruamel-yaml 'meson-python<0.13.0,>=0.11.0' 'setuptools<60.0' "Cython<3.0" nbformat pytest testfixtures mock nbconvert

# Clone the repository
echo "Cloning the repository from $PACKAGE_URL..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
echo "Checking out version $PACKAGE_VERSION..."
git checkout $PACKAGE_VERSION

echo "Building the package using setup.py..."
#Compiled extensions are unavailable.
python3 setup.py build_ext --inplace

# Build package
echo "Attempting to install the package..."
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
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
