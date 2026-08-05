#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : abseil-cpp
# Version       : 20240116.2
# Source repo   : https://github.com/abseil/abseil-cpp
# Tested on     : UBI:10.1
# Language      : Python, C++
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=abseil-cpp
PACKAGE_DIR=abseil-cpp
PACKAGE_VERSION=${1:-20240116.2}
PACKAGE_URL=https://github.com/abseil/abseil-cpp

# install core dependencies
yum install -y python3.12-pip python3.12-devel git  gcc gcc-c++ cmake wget
python3.12 -m pip install cmake setuptools ninja

# Setting Paths and creating directories
WORK_DIR=$(pwd)
mkdir $WORK_DIR/abseil-prefix
PREFIX=$WORK_DIR/abseil-prefix

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

Source_DIR=$(pwd)
mkdir -p $Source_DIR/local/abseilcpp
abseilcpp=$Source_DIR/local/abseilcpp

# Build Abseil-cpp
echo "$PACKAGE build starts!!"

mkdir build
cd build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..

cmake --build .
cmake --install .

cd $Source_DIR

cp -r  $PREFIX/* $abseilcpp/
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH

#create pyproject.toml file
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/abseil-cpp/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "Build and installation completed successfully."
echo "There are no test cases available. skipping the test cases"
