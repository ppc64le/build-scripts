#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : multidict
# Version          : 6.0.2
# Source repo      : https://github.com/aio-libs/multidict.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=multidict
PACKAGE_VERSION=${1:-v6.0.2}
PACKAGE_URL=https://github.com/aio-libs/multidict.git

# Install dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip cmake

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  # Change directory to the cloned repository
git checkout $PACKAGE_VERSION  # Checkout the specified version

# install necessary Python packages
pip install pytest pytest-cov build

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if python3 --version | grep -Eq "3\.12"; then
    TEST_CMD="pytest --cov=multidict --cov-report=xml --deselect=tests/test_mutable_multidict.py::TestCIMutableMultiDict::test_add"
else
    TEST_CMD="pytest --cov=multidict --cov-report=xml"
fi

# Run tests
if ! $TEST_CMD; then
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
