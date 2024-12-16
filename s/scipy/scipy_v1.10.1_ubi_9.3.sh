#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scipy
# Version       : v1.10.1
# Source repo   : https://github.com/scipy/scipy
# Tested on     : UBI 9.3
# Language      : Python, C, Fortran, C++, Cython, Meson
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scipy
PACKAGE_VERSION=${1:-v1.10.1}
PACKAGE_URL=https://github.com/scipy/scipy
PYTHON_VER=${2:-"3.11"}

OS_NAME=$(cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}')

# install core dependencies
yum install -y gcc gcc-c++ gcc-fortran pkg-config openblas-devel python${PYTHON_VER} python${PYTHON_VER}-pip python${PYTHON_VER}-devel git atlas

# install scipy dependency (numpy wheel gets built and installed) and build-setup dependencies
pip${PYTHON_VER} install meson ninja 'numpy<1.23' 'setuptools<60.0' Cython==0.29.37
pip${PYTHON_VER} install 'meson-python<0.15.0,>=0.12.1'
pip${PYTHON_VER} install pybind11
pip${PYTHON_VER} install 'patchelf>=0.11.0'
pip${PYTHON_VER} install 'pythran<0.15.0,>=0.12.0'
pip${PYTHON_VER} install pooch pytest
pip${PYTHON_VER} install build


# Cloning the repository from remote to local
if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME  
else  
  cd $PACKAGE_SOURCE_DIR
fi


git checkout $PACKAGE_VERSION
git submodule update --init

# build and install
if ! pip${PYTHON_VER} install -e . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# run specific tests using pytest
if ! python${PYTHON_VER} -m pytest scipy/interpolate/tests/test_polyint.py scipy/linalg/tests/test_basic.py; then
    echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
fi

