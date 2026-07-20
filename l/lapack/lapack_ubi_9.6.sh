#!/bin/bash 
# -----------------------------------------------------------------------------
#
# Package         : lapack
# Version         : v3.12.1
# Source repo     : https://github.com/Reference-LAPACK/lapack
# Tested on       : UBI: 9.6
# Language        : C
# Ci-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=lapack
PACKAGE_VERSION=${1:-v3.12.1}
PACKAGE_URL=https://github.com/Reference-LAPACK/lapack
PACKAGE_DIR=./lapack

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

echo "Installing required dependencies..."
yum install -y git gcc gcc-c++ gcc-gfortran make cmake wget

echo "Cloning LAPACK source..."
SCRIPT_DIR=$(pwd)
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Building LAPACK with tests enabled..."
mkdir cmake_build && cd cmake_build

if ! cmake .. -DBUILD_TESTING=ON -DBUILD_SHARED_LIBS=ON -DLAPACKE=ON -DCMAKE_INSTALL_PREFIX=$SCRIPT_DIR/lapack-prefix ; then
    echo "------------------$PACKAGE_NAME:Configure_fails---------------------"
    exit 1
fi

if ! make -j$(nproc) ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    exit 2
fi

cmake --install .
cd ..

mkdir -p local/lapack
cp -r $SCRIPT_DIR/lapack-prefix/* local/lapack/

export LD_LIBRARY_PATH=$SCRIPT_DIR/lapack-prefix/lib:$SCRIPT_DIR/lapack-prefix/lib64:${LD_LIBRARY_PATH}
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/l/lapack/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g" pyproject.toml
mkdir -p local

echo "Running LAPACK tests..."
if ! ctest --output-on-failure ; then
    echo "------------------$PACKAGE_NAME:Test_fails---------------------"
    exit 3
fi

echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
exit 0
