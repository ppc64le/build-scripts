#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : python-oracledb
# Version       : v2.5.1
# Source repo   : https://github.com/oracle/python-oracledb.git
# Tested on     : UBI 9.3
# Language      : Python, Cython, Plsql
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

# Install dependencies
yum install -y python3.12 python3.12-devel python3.12-pip git openssl-devel gcc-toolset-13 cmake wget

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

# Clone the python-oracledb package
PACKAGE_NAME=python-oracledb
PACKAGE_VERSION=${1:-v2.5.1}
PACKAGE_URL=https://github.com/oracle/python-oracledb.git
CURRENT_DIR=$(pwd) 

echo " ----------------------------------- Installing Dependencies ----------------------------------- "
python3.12 -m pip install setuptools wheel build pytest

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

echo " ----------------------------------- Installing Package ----------------------------------- "
python3.12 -m pip install .

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
python3.12 -c "import oracledb; print(oracledb.__file__)"
python3.12 -c "import oracledb; print(oracledb.__version__)" 

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi 