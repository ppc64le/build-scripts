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
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PYTHON_VERSION=3.11

# Install dependencies
yum install -y python311 python$PYTHON_VERSION-devel python$PYTHON_VERSION-pip git openssl-devel gcc cmake wget

# Install dependency rustc
export RUST_VERSION="1.80.0"
wget -q -O rustup-init.sh https://sh.rustup.rs
bash rustup-init.sh -y
export PATH=$PATH:$HOME/.cargo/bin
rustup toolchain install ${RUST_VERSION}
rustup default ${RUST_VERSION}
rustc --version | grep "${RUST_VERSION}"

# Clone the python-oracledb package
PACKAGE_NAME=python-oracledb
PACKAGE_VERSION=${1:-v2.5.1}
PACKAGE_URL=https://github.com/oracle/python-oracledb.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Setup virtual environment for python
python$PYTHON_VERSION -m venv oracledb-env
source oracledb-env/bin/activate
python3 -m pip install pytest hypothesis build

# Install the package
python3 -m build
python3 -m pip install -e .

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
python3 -c "import oracledb; print(oracledb.__file__)"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     
     # Deactivate python environment (oracledb-env)
	 deactivate

     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi

