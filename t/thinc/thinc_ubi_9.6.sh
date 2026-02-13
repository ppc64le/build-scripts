#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : thinc
# Version          : 8.3.6
# Source repo      : https://github.com/explosion/thinc
# Tested on        : UBI:9.6
# Language         : python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Varad Ahirwadkar <varad.ahirwadkar1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=thinc
PACKAGE_VERSION=${1:-8.3.6}
PACKAGE_URL=https://github.com/explosion/thinc
PACKAGE_DIR=thinc
CURRENT_DIR="${PWD}"
export BLIS_ARCH=generic

# Install dependencies
dnf install git python3.12-devel gcc gcc-c++ python3.12-pip -y

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout release-v$PACKAGE_VERSION

echo "Installing package dependencies..."
python3.12 -m pip install wheel
python3.12 -m pip install -r requirements.txt

echo "Installing the package..."
if ! python3.12 -m pip install --no-build-isolation . ; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Failed"
        exit 1
fi

echo "Building wheel file..."
python3.12 -m pip wheel . --wheel-dir /thincwheels
python3.12 -m pip show thinc

echo "Running tests..."
cd ..
if ! (python3.12 -m pytest --pyargs thinc); then
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
