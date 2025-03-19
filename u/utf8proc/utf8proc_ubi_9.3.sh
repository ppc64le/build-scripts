#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : utf8proc
# Version       : 2.6.1
# Source repo   : https://github.com/JuliaStrings/utf8proc.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
PACKAGE_NAME=utf8proc
PACKAGE_VERSION=${1:-v2.6.1}
PACKAGE_URL=https://github.com/JuliaStrings/utf8proc.git
PACKAGE_DIR=utf8proc
WORK_DIR=$(pwd)

# Install dependencies and tools.
yum install -y wget git gcc-toolset-13-gcc cmake python3-devel python3-pip
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
# Download the source package
echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/ppc64le/build-scripts/d958955bd1c9fa9633a2a2b194d4b2fd0ecfe5a6/u/utf8proc/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml
mkdir prefix
export PREFIX=$(pwd)/prefix

mkdir build
cd build
cmake -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
  -DBUILD_SHARED_LIBS=1 \
  ..
cmake --build . --target install
cd ..
mkdir -p local/$PACKAGE
cp -r prefix/* local/$PACKAGE/
echo "installing..."
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
echo "Build and installation completed successfully."
echo "There are no test cases available. skipping the test cases"
