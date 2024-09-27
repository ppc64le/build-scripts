#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : mpld3
# Version       : 0.5.10
# Source repo : https://github.com/mpld3/mpld3
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Note: No test cases are available for this package.
# -----------------------------------------------------------------------------
 
# Variables
PACKAGE_NAME=mpld3
PACKAGE_VERSION=${1:-0.5.10}
PACKAGE_URL=https://github.com/mpld3/mpld3
 
# Step 1: Download and extract the mpld3 source code
echo "Downloading $PACKAGE_NAME-$PACKAGE_VERSION..."
wget https://files.pythonhosted.org/packages/90/58/19378f4189a034eb3efc17b133426b8551af1d3b2c70d641a63124579629/$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
 
echo "Extracting $PACKAGE_NAME-$PACKAGE_VERSION..."
tar -xvf $PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
cd $PACKAGE_NAME-$PACKAGE_VERSION
 
# Step 2: Install necessary development tools and libraries
echo "Installing required dependencies..."
yum install -y python3-devel wget curl python3-setuptools python3-pip \
    libjpeg-devel zlib-devel freetype-devel lcms2-devel libwebp-devel \
    tcl-devel tk-devel gcc gcc-c++ make
 
# Step 3: Install dependencies using pip
echo "Installing Python dependencies..."
pip3 install numpy matplotlib pillow wheel build
 
# Step 4: Fix the deprecation warning in setup.py (description-file)
echo "Fixing deprecation warning in setup.py..."
sed -i 's/description-file/description_file/' setup.py
 
# Step 5: Build the mpld3 package using the modern build tool
echo "Building the package..."
python3 -m build
 
# Step 6: Run the tests if the 'tests/' directory exists
if [ -d "tests/" ]; then
    echo "Running tests..."
    python3 -m unittest discover tests/
else
    echo "No tests/ directory found, skipping test execution."
fi
 
# Step 7: Notify user about the wheel file location
echo "The wheel file has been created in the dist/ directory."
 
# Optional: Clean up the tar.gz file after extraction
echo "Cleaning up..."
rm ../$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
