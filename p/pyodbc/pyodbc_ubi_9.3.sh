#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : pyodbc
# Version       : 4.0.34
# Source repo   : https://github.com/mkleehammer/pyodbc
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijeet Dandekar <Abhijeet.Dandekar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyodbc
PACKAGE_VERSION=${1:-4.0.34}
PACKAGE_URL=https://github.com/mkleehammer/pyodbc

yum install -y wget gcc gcc-c++ gcc-gfortran git make python-devel  openssl-devel unixODBC-devel

# Clone the repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install pytest
pip install pytest

#install chardet and psutil
pip install "chardet<5,>=3.0.2" --force-reinstall
pip install psutil

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_Success"
    exit 0
fi

# No need to run tests, as testing requires running a PostgreSQL container and connecting to it.
