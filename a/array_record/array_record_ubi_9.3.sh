#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : array_record
# Version       : v0.5.0
# Source repo   : https://github.com/google/array_record
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
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
PACKAGE_VERSION=${1:-v0.5.0}
PACKAGE_URL="https://github.com/google/array_record"
WORK_DIR=$(pwd)
PACKAGE_DIR=array_record/build-dir

echo "Installing dependencies..."
yum install -y python3-pip python3 python python3-devel git gcc-toolset-13 cmake wget

# Ensure pip is up-to-date
pip3 install --upgrade pip

# Install setuptools and wheel for building
pip3 install setuptools wheel

WORK_DIR=$(pwd)

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install required Python packages
pip3 install setuptools wheel absl-py etils[epath]

# Modify setup.py to ensure 'python' and 'beam' are included
sed -i "s/packages=find_packages()/packages=[\"array_record\", \"array_record.python\"]/g" setup.py

cd $WORK_DIR
mkdir -p $PACKAGE_NAME/build-dir/array_record
cd $WORK_DIR/array_record
cp -r python $WORK_DIR/$PACKAGE_NAME/build-dir/array_record
cp setup.py $WORK_DIR/$PACKAGE_NAME/build-dir/
cd $WORK_DIR/$PACKAGE_NAME/build-dir


# Build the package and create a wheel file
echo "Building the package..."
pip3 install .
if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail | wheel_built_fails"
    exit 1
fi

echo "$PACKAGE_NAME $PACKAGE_VERSION: Wheel built successfully"

echo "tests"
if ! python3 -c "import array_record; import array_record.python;"; then
    echo "------------------$PACKAGE_NAME:TEST__fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail | TEST_fails"
    exit 1
fi
echo "$PACKAGE_NAME $PACKAGE_VERSION: TESTS successfully"
