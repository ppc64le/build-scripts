#!/bin/bash 
# ----------------------------------------------------------------------------
#
# Package       : gensim
# Version       : 4.3.3
# Source repo   : https://github.com/RaRe-Technologies/gensim
# Tested on     : UBI: 9.5
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Tejas Badjate <Tejas.Badjate@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e  # Exit immediately if a command fails

PACKAGE_VERSION=${1:-4.3.3}
PACKAGE_NAME=gensim
PACKAGE_DIR=./gensim
PACKAGE_URL=https://github.com/RaRe-Technologies/gensim

# Install system dependencies
yum install -y git gcc gcc-c++ wget atlas pkg-config openblas-devel atlas-devel pkgconfig cmake gcc-gfortran make

# Ensure Python 3.12 is installed
dnf install -y python3.12 python3.12-pip python3.12-test python3.12-devel
python3.12 --version
pip3.12 --version

# Upgrade pip and install required dependencies
python3.12 -m pip install --upgrade pip 
python3.12 -m pip install wheel meson pytest requests ruamel-yaml nbformat testfixtures mock nbconvert
python3.12 -m pip install numpy==1.26.4 scipy==1.13.1 Cython 

# Clone the repository
git clone $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
TOXENV=py312
python3.12 setup.py build_ext --inplace

# Build package
if !(python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
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
