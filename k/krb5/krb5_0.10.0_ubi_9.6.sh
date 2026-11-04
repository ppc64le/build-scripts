#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pykrb5
# Version          : v0.10.0
# Source repo      : https://github.com/jborean93/pykrb5.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pykrb5
PACKAGE_VERSION=${1:-v0.10.0}
PACKAGE_URL=https://github.com/jborean93/pykrb5.git

# Install dependencies and tools
yum install -y git wget gcc gcc-c++ make python3.12 python3.12-devel python3.12-pip krb5-devel krb5-libs

# KDC and client tools are needed by the k5test based unit tests
yum install -y krb5-server krb5-workstation || echo "krb5-server/krb5-workstation not available, KDC based tests may fail"

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.12 -m pip install --upgrade pip
python3.12 -m pip install pytest wheel build "k5test>=0.10.4"

# Build and install (Cython is pinned in pyproject.toml build requirements)
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Build the wheel
python3.12 -m build --wheel

# Run tests
if ! python3.12 -m pytest -v ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
