#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyproj
# Version       : 3.7.0
# Source repo   : https://github.com/pyproj4/pyproj
# Tested on     : UBI 9.3
# Language      : Python, Cython
# Ci-Check  : True
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

yum install -y git gcc-c++ gcc wget make cmake python3.11 python3.11-pip python3.11-devel yum-utils apr-devel perl openssl-devel automake autoconf libtool sqlite-devel libtiff-devel  curl-devel diffutils

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
PACKAGE_VERSION=${1:-3.7.0}
PACKAGE_URL=https://github.com/pyproj4/pyproj.git
PACKAGE_DIR=pyproj

cd $HOME_DIR

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

export PROJ_DIR=$HOME_DIR/proj.4/build
export PROJ_LIBDIR=$HOME_DIR/proj.4/build/lib
export PROJ_INCDIR=$HOME_DIR/proj.4/src
export PROJ_DATA=$HOME_DIR/proj.4/build/data

# build and install
if ! python3.11 -m pip install . ; then
     echo "------------------$PACKAGE_NAME::build_install_fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Install_Fail"
     exit 1
else
     echo "------------------$PACKAGE_NAME::Build_Install_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Build_Install_Success"
     python3.11 -m pip show pyproj
fi

# test using import and printing version
cd ..
python3.11 -c "import pyproj; print(pyproj.__version__)"
if [ $? == 0 ]; then
        echo "------------------$PACKAGE_NAME:test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Test_Success"
        exit 0
else
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Test_Fails"
        exit 2
fi
