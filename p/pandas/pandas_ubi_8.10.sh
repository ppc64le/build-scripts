#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v2.2.2
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI 8.10
# Language      : Python, C, Cython, Html
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies
yum install -y python311 python3.11-devel python3.11-pip git gcc gcc-c++ cmake ninja-build

# Clone the pandas package.
PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v2.2.2}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Setup virtual environment for python
python3.11 -m venv pandas-env
source pandas-env/bin/activate
pip3.11 install Cython pytest hypothesis build meson meson-python

# Build the package and create whl file (This is dependent on cython)
python3 -m build --wheel

# Install wheel
python3 -m pip install dist/pandas-2.2.2-cp311-cp311-linux_ppc64le.whl
if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Build_Success"
else
     echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Build_Fail"
     exit 1
fi

# Test the package
cd ..
python3 -m pip show pandas
python3 -c "import pandas; print(pandas.__file__)"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     
     # Deactivate python environment (pandas-env)
	 deactivate

     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi

