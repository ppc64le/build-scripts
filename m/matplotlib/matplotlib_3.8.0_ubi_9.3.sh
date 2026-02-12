#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.8.0
# Source repo :  https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
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

echo "Installing dependencies..."
yum install -y python3-pip python3 python3 python3-devel git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ cmake wget
yum install -y openblas-devel ninja-build
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel
echo "Dependencies installed."
 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
echo "Cloning the $PACKAGE_NAME package..."
# Clone the matplotlib package.
PACKAGE_NAME=matplotlib
PACKAGE_VERSION=${1:-v3.8.0}
PACKAGE_URL=https://github.com/matplotlib/matplotlib.git
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init
echo "Cloned and checked out to version $PACKAGE_VERSION."
 
echo "Downloading and preparing qhull..."
# Download qhull
# Create build directory
mkdir -p build
wget https://github.com/qhull/qhull/archive/refs/tags/v8.0.2.tar.gz -O qhull-8.0.2.tar.gz
tar -xzf qhull-8.0.2.tar.gz
mv qhull-8.0.2 build/qhull-2020.2

pip3 install pytest hypothesis build meson pybind11 meson-python
echo "Python environment set up."
 
echo "Installing dependencies for $PACKAGE_NAME..."
# Install package dependencies
pip3 install 'numpy<2' fontTools setuptools-scm contourpy kiwisolver python-dateutil cycler "pyparsing<3.2" pillow certifi
pip3 install --upgrade setuptools
echo "Dependencies installed."
 
echo "Building and installing $PACKAGE_NAME..."
# Build and Install the package (This is dependent on numpy, pillow)
if ! (pip3 install -e .); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi
echo "$PACKAGE_NAME installed successfully."
 
echo "Running tests for $PACKAGE_NAME..."
# Test the package
if ! (pytest ./lib/matplotlib/tests/test_units.py); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
