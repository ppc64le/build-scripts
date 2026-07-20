#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cffi
# Version          : 1.15.1
# Source repo      : https://github.com/python-cffi/cffi.git
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
PACKAGE_NAME=cffi
PACKAGE_VERSION=${1:-v1.15.1}
PACKAGE_URL=https://github.com/python-cffi/cffi.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel python3-devel python3-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  

# Install additional dependencies
pip install pytest py

# Install
if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
if ! pytest -k "not test_parsing and not test_zintegration" ; then
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
