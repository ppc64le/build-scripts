#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pycryptodome
# Version       : v3.21.0
# Source repo   : https://github.com/Legrandin/pycryptodome
# Tested on     : UBI 9.3
# Language      : C, Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
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
PACKAGE_DIR=pycryptodome

# Install required dependencies
yum update -y
yum install -y git gcc python3 python3-devel.ppc64le gcc g++ gcc-c++ make wget 

#Clone the repository 	
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install python dependencies
python3 -m pip install cffi
python3 -m pip install build
python3 -m pip install -r requirements-test.txt

# Install via pip3
if ! pip install .; then
     echo "------------------$PACKAGE_NAME:install_fails------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Failed"  
     exit 1
fi

# Test the package
if ! python3 -m Crypto.SelfTest ; then
     echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
     exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
