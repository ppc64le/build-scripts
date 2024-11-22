#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : pyodbc
# Version       : 4.0.34
# Source repo   : https://github.com/mkleehammer/pyodbc.git
# Tested on     : UBI:9.3
# Language      : Python
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
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=pyodbc
PACKAGE_VERSION=${1:-4.0.34}
PACKAGE_URL=https://github.com/mkleehammer/pyodbc.git

# Install dependencies and tools.
yum install -y wget gcc gcc-c++ gcc-gfortran git make  python-devel  openssl-devel cmake unixODBC-devel

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
