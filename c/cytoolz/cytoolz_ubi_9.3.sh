#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cytoolz
# Version          : 0.12.3
# Source repo      : https://github.com/pytoolz/cytoolz.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
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
PACKAGE_NAME=cytoolz
PACKAGE_VERSION=${1:-0.12.3}
PACKAGE_URL=https://github.com/pytoolz/cytoolz.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip

#install package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install additional dependencies
pip install .
pip install pytest wheel build Cython==0.29.21

#install
if ! python3 -m setup build; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if [ "$PACKAGE_VERSION" == "0.10.1" ]; then
    # For version 0.10.1, run pytest from the specific directory
    if [[ -d "/cytoolz/cytoolz/tests" ]]; then
        cd "/cytoolz/cytoolz/tests"
        if ! pytest; then
            echo "------------------$PACKAGE_NAME: Install_success_but_test_fails---------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
            exit 2
        fi
    else
        echo "Directory '/cytoolz/cytoolz/tests' does not exist."
        exit 1
    fi
else
    # For version 0.12.3 or any other version, run pytest in the current directory
    if ! pytest; then
        echo "------------------$PACKAGE_NAME: Install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
        exit 2
    fi
fi
echo "------------------$PACKAGE_NAME: Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass | Both_Install_and_Test_Success"
exit 0
