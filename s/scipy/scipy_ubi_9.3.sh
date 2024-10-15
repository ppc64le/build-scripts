#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scipy
# Version       : v1.14.1
# Source repo   : https://github.com/scipy/scipy
# Tested on     : UBI 9.3
# Language      : Python, C, Fortran, C++, Cython, Meson
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scipy
PACKAGE_VERSION=${1:-v1.14.1}
PACKAGE_URL=https://github.com/scipy/scipy

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

# install core dependencies
yum install -y gcc gcc-c++ gcc-fortran pkg-config openblas-devel python3.11 python3.11-pip python3.11-devel git atlas

# change symbolic links so that python can find them
#ln -s /usr/lib64/atlas/libtatlas.so.3 /usr/lib64/atlas/libtatlas.so

# install scipy dependency(numpy wheel gets built and installed) and build-setup dependencies
python3.11 -m pip install meson ninja numpy 'setuptools<60.0' Cython
python3.11 -m pip install 'meson-python<0.15.0,>=0.12.1'
python3.11 -m pip install pybind11
python3.11 -m pip install 'patchelf>=0.11.0'
python3.11 -m pip install 'pythran<0.15.0,>=0.12.0'
python3.11 -m pip install build

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# build and install
if ! python3.11 -m pip install -e . --no-build-isolation; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# test that installation happened successfully
python3.11 -m pip show scipy

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
