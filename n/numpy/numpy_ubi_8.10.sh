#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v2.0.1
# Source repo   : https://github.com/numpy/numpy.git
# Tested on     : UBI 8.10
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

yum install -y python311 python3.11-devel python3.11-pip git gcc-gfortran.ppc64le gcc-c++
yum install -y openblas-devel openblas --enablerepo=codeready-builder-for-rhel-8-ppc64le-rpms
pip3.11 install tox Cython pytest hypothesis build meson

#Clone the package.

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init

#Build the package and create whl file (Wheel file gets generated in dist folder)
python3.11 -m build --wheel  -Cbuilddir=builddir -Csetup-args=-Dallow-noblas=false -Csetup-args=-Dblas=openblas -Csetup-args=-Dlapack=openblas

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

#Install and Test the package
cd ..
python3.11 -m pip install numpy/dist/numpy-2.0.1-cp311-cp311-linux_ppc64le.whl
python3.11 -c "import numpy; a=numpy.array([[1. ,2. ,3.], [4. ,5. ,6.]]); print(a)"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi

