#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cytoolz
# Version          : 1.1.0
# Source repo      : https://github.com/pytoolz/cytoolz.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <Shivansh.S1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=cytoolz
PACKAGE_VERSION=${1:-1.1.0}
PACKAGE_URL=https://github.com/pytoolz/cytoolz.git
PACKAGE_DIR=./cytoolz
CURRENT_DIR=$(pwd)

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel python3.14-devel python3.14-pip


# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install additional dependencies
python3.14 -m pip install Cython pytest setuptools
python3.14 -m pip install toolz==1.1.0

# Install
if ! python3.14 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
cd $CURRENT_DIR
mkdir $CURRENT_DIR/test_dir
cp -r $CURRENT_DIR/$PACKAGE_NAME/cytoolz/tests $CURRENT_DIR/test_dir
if ! pytest $CURRENT_DIR/test_dir; then
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
