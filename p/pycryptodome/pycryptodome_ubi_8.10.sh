#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pycryptodome
# Version       : v3.21.0
# Source repo   : https://github.com/Legrandin/pycryptodome
# Tested on     : UBI 8.10
# Language      : C, Python
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Balavva.Mirji@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 
PACKAGE_NAME=pycryptodome
PACKAGE_VERSION=${1:-v3.21.0}
PACKAGE_URL=https://github.com/Legrandin/pycryptodome
BUILD_HOME=$(pwd)

PYTHON_VERSION=3.11

# Install required dependencies
yum update -y
yum install -y git gcc python$PYTHON_VERSION python$PYTHON_VERSION-pip

#Clone the repository 	
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python$PYTHON_VERSION -m venv pycryptodome-env
source pycryptodome-env/bin/activate

python3 -m pip install cffi
python3 -m pip install build
python3 -m pip install -r requirements-test.txt

# Build the package and create the whl file in /dist folder 
if ! python3 -m build --wheel ; then
    echo "------------------$PACKAGE_NAME::Build_Fail---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Build_Fail"
    exit 1
else
    echo "------------------$PACKAGE_NAME::Build_Success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Success |  Build_Success"
fi  

# Install the wheel 
if ! pip3 install dist/pycryptodome-*.whl ; then
     echo "------------------$PACKAGE_NAME::Install_Fail---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Install_Fail"
     exit 2
else
     echo "------------------$PACKAGE_NAME::Install_Success-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Success |  Install_Success"
fi

# Test the package
if ! python3 -m Crypto.SelfTest ; then
     echo "------------------$PACKAGE_NAME::Test_Fail---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
else
     echo "------------------$PACKAGE_NAME::Test_Success-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Success |  Test_Success"
     deactivate
     exit 0
fi