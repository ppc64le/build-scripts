#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v2.0.1
# Source repo   : https://github.com/numpy/numpy.git
# Tested on     : UBI 9.3
# Language      : Python, C, C++, Cython
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v2.0.1}
PACKAGE_URL=https://github.com/numpy/numpy.git

yum install -y python311 python3.11-devel python3.11-pip git openblas-devel openblas gcc-gfortran.ppc64le gcc-c++
pip3.11 install tox Cython pytest hypothesis build meson

#Clone the package.

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init

#Build the package
python3.11 -m build -Cbuilddir=builddir -Csetup-args=-Dallow-noblas=false -Csetup-args=-Dblas=openblas -Csetup-args=-Dlapack=openblas

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Build_Success"
else
     echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Build_Fail"
     exit 1
fi
