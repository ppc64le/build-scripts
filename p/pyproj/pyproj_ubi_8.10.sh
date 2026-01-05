#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyproj
# Version       : 3.6.1
# Source repo   : https://github.com/pyproj4/pyproj
# Tested on     : UBI 8.10
# Language      : Python, Cython
# Ci-Check  : False
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

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

PYTHON_VERSION=3.11

yum install -y git gcc-c++ gcc wget make cmake python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel yum-utils apr-devel perl openssl-devel automake autoconf libtool sqlite-devel libtiff-devel  curl-devel diffutils

cd $HOME_DIR
git clone https://github.com/OSGeo/proj.4.git
cd proj.4
git checkout 9.3.0
git submodule update --init

mkdir build
cd build
cmake ..

# build and install PROJ - required for buiding pyproj from source. pyproj 3.5+ required PROJ 9+ - https://pyproj4.github.io/pyproj/stable/installation.html
make -j4

PACKAGE_NAME=pyproj
PACKAGE_VERSION=${1:-3.6.1}
PACKAGE_URL=https://github.com/pyproj4/pyproj.git

cd $HOME_DIR

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

python$PYTHON_VERSION -m venv pyproj-env
source pyproj-env/bin/activate

export PROJ_DIR=../proj.4/build
export PROJ_LIBDIR=../proj.4/build/lib
export PROJ_INCDIR=../proj.4/src
export PROJ_DATA=/proj.4/build/data
export PROJ_WHEEL=1

# install build dependencies
python3 -m pip install 'setuptools>=61.0.0' wheel 'cython>=3'

# build wheel in dist folder
if ! python3 setup.py bdist_wheel; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# install wheel
if ! python3 -m pip install dist/pyproj*.whl; then
     echo "------------------$PACKAGE_NAME::install_fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Install_Fail"
     exit 2
else
     echo "------------------$PACKAGE_NAME::Install_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Install_Success"
     python3 -m pip show pyproj
fi

# test using import and printing version
cd ..
python3 -c "import pyproj; pyproj.show_versions()"
if [ $? == 0 ]; then
        echo "------------------$PACKAGE_NAME:test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Test_Success"
        deactivate
        exit 0
else
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Test_Fails"
        exit 2
fi
