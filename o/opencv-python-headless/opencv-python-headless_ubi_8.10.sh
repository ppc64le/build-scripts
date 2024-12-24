#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opencv-python-headless
# Version       : 4.10.0.84
# Source repo   : https://github.com/opencv/opencv-python.git
# Tested on     : UBI 8.10
# Language      : Python, Shell
# Travis-Check  : False
# Script License: Apache License 2.0
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=opencv-python
PACKAGE_VERSION=${1:-84}
PACKAGE_URL=https://github.com/opencv/opencv-python

PYTHON_VERSION=3.11

# install core dependencies
yum install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel gcc gcc-c++ gcc-gfortran gcc-toolset-10 git
yum install -y openblas-devel --enablerepo=codeready-builder-for-rhel-8-ppc64le-rpms

source /opt/rh/gcc-toolset-10/enable

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone source repository
git clone --recursive $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

export ENABLE_HEADLESS=1

# install dependency
python3 -m pip install numpy
# fix header file related error as mentioned on https://github.com/opencv/opencv/issues/11709
ln -s /usr/lib64/python3.11/site-packages/numpy/core/include/numpy/ /usr/include/numpy

# build wheel in opencv-python/wheels folder
if ! python3 -m pip wheel . --verbose -w wheels; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

cd ..

# install wheel
if ! python3 -m pip install opencv-python/wheels/opencv_python_headless*.whl; then
     echo "------------------$PACKAGE_NAME::Install_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Install_Fail"
     exit 2
else
     echo "------------------$PACKAGE_NAME::Install_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Install_Success"
fi

# test after installation
python3 -c "import cv2 as cv; print(cv.__version__)"
if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
