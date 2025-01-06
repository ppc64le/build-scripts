#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v1.5.3
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI:9.3
# Language      : Python, C, Cython, Html
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v1.5.3}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git
 
# Install system dependencies including SQLite and LZMA libraries
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel wget xz zlib-devel cmake openblas-devel sqlite-devel xz-devel python-devel
 
 
# Clone the pandas repository and checkout the required version
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
 
# Initialize and update submodules
git submodule update --init --recursive
 
# Install dependencies for Pandas and NumPy
pip install cython==0.29.32
pip install numpy==1.21.6
python3 -m pip install wheel oldest-supported-numpy

# Install
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Install_Success"
    exit 0
fi

#skipping the testcases as it is taking more than 5 hours.
