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

# Install dependencies and tools
yum install -y wget git gcc-toolset-13-gcc cmake 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Download the source package
echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME

# Initialize git submodules
git submodule update --init

# Checkout the specified version
git checkout $PACKAGE_VERSION

# Setup prefix for installation
mkdir prefix
export PREFIX=$(pwd)/prefix

# Create build directory
mkdir build
cd build

# Run cmake to configure the build
cmake -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
  -DBUILD_SHARED_LIBS=1 \
  ..
# Build and install
cmake --build .
cmake --build . --target install

echo "Build and installation completed successfully."
echo "There are no test cases available. Skipping the test cases."
