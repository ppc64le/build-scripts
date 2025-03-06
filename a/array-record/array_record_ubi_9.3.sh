#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : array_record
# Version       : v0.4.1
# Source repo   : https://github.com/google/array_record
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

# Variables
PACKAGE_NAME="array_record"
PACKAGE_VERSION="v0.4.1"
PACKAGE_URL="https://github.com/google/array_record"
PACKAGE_DIR=array_record
CURRENT_DIR="${PWD}"

echo "Installing dependencies..."
# Install system dependencies
yum install -y python3-pip python3 python python3-devel git gcc-toolset-13 cmake wget

echo "Cloning the repository..."
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init
echo "Repository cloned and checked out to version $PACKAGE_VERSION."

# Install required Python packages
pip3 install array_record==0.4.1
pip3 install --upgrade pip setuptools absl-py etils[epath]

echo "Building and installing $PACKAGE_NAME..."
# Build the package and create a wheel file
if ! python3 setup.py bdist_wheel --dist-dir="$CURRENT_DIR/" ; then
    echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail | wheel_built_fails"
    exit 1
fi

echo "Running tests for $PACKAGE_NAME..."
# Test the package
if ! python3 -c "import array_record" ; then
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
