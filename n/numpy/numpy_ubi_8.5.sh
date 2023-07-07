#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v1.20.1, v1.20.2
# Source repo   : https://github.com/numpy/numpy.git
# Tested on     : UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# 
# ----------------------------------------------------------------------------

PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v1.20.1}
PACKAGE_URL=https://github.com/numpy/numpy.git

yum install -y python38 python38-devel python3-pip git gcc-gfortran.ppc64le
pip3.8 install tox Cython pytest hypothesis

#clone the package.

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build the package 

python3.8 setup.py build

#Build and test the package.
python3.8 runtests.py
