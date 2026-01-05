#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyhdf
# Version          : v0.11.6
# Source repo      : https://github.com/fhs/pyhdf
# Tested on        : UBI:9.3
# Language         : C,Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyhdf
PACKAGE_VERSION=${1:-v0.11.6}
PACKAGE_URL=https://github.com/fhs/pyhdf
PACKAGE_DIR=pyhdf

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3 python3-devel python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel 

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

# Install hdf4
git clone --depth 1 --branch hdf4.3.0 https://github.com/HDFGroup/hdf4.git
cd hdf4
./configure --enable-hdf4-xdr --enable-shared --disable-static --disable-fortran --disable-netcdf --disable-java --enable-production --with-zlib --prefix=/usr/local
make -j$(nproc)
make install

export LIBRARY_DIRS=/usr/local/lib
export INCLUDE_DIRS=/usr/local/include
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install -U pip numpy pytest

#Build package
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test package
if ! (pytest && python3 examples/runall.py) ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
