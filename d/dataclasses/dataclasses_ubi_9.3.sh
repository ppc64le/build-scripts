#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : dataclasses
# Version       : 0.8
# Source repo   : https://github.com/ericvsmith/dataclasses.git
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
PACKAGE_NAME=dataclasses
PACKAGE_VERSION=${1:-0.8}
PACKAGE_URL=https://github.com/ericvsmith/dataclasses.git

# Install dependencies and tools.
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel

#Install python3.6
wget https://www.python.org/ftp/python/3.6.15/Python-3.6.15.tgz
tar xzf Python-3.6.15.tgz
cd Python-3.6.15
./configure --enable-optimizations
make altinstall
cd ..

python3.6 -m venv dataclasses_venv
source dataclasses_venv/bin/activate

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install pytest
python3.6 -m pip install pytest

#install
if ! (python3.6 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest; then
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
