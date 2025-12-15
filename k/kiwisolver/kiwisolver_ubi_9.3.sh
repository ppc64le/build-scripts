#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : kiwisolver
# Version       : 1.2.0
# Source repo   : https://github.com/nucleic/kiwi.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
# Exit immediately if a command exits with a non-zero status
set -e
#variables
PACKAGE_NAME=kiwi
PACKAGE_VERSION=${1:-1.2.0}
PACKAGE_URL=https://github.com/nucleic/kiwi.git

# Install dependencies and tools.
yum install -y git wget gcc gcc-c++ python-pip python3-devel python3 python3-pip
pip install build pytest wheel cppy

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
pip install .
#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Check if the 'tests' folder exists
if [ -d "kiwi/tests" ]; then
    # Run tests using pytest
    if ! pytest; then
            echo "-------------------- $PACKAGE_NAME: build success but test fails --------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
            exit 2
    else
        echo "-------------------- $PACKAGE_NAME: build & test both success --------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Build_and_Test_Success"
    fi
else
    # Skip tests if 'tests' folder is not available
    echo "-------------------- $PACKAGE_NAME: tests skipped as 'tests' folder is not available --------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Tests_Skipped"
fi
