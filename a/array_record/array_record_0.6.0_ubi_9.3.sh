#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : array_record
# Version       : v0.6.0
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
PACKAGE_VERSION=${1:-v0.6.0}
PACKAGE_URL="https://github.com/google/array_record"
PACKAGE_DIR=array_record
CURRENT_DIR="${PWD}"
# array-record not tagged to use v0.6.0, used hard commit for v0.6.0 
PACKAGE_COMMIT="7e299eae0db0d7bfc20f7c1e1548bf86cdbfef5e"
echo "Installing dependencies..."
# Install system dependencies
yum install -y python3-pip python3 python python3-devel git gcc-toolset-13 cmake wget

echo "Cloning the repository..."
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_COMMIT
git submodule update --init
echo "Repository cloned and checked out to version $PACKAGE_VERSION."

# Install required Python packages
pip3 install --upgrade pip setuptools absl-py etils[epath]

echo "Building and installing $PACKAGE_NAME..."
# Build the package and create a wheel file
if !(python3 setup.py install); then
    echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail | wheel_built_fails"
    exit 1
fi
# Install pre-requisite wheels and dependencies
echo "Build and installation completed successfully."
echo "There are no test cases available. skipping the test cases"
