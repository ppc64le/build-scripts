#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numexpr
# Version       : v2.14.1
# Source repo   : https://github.com/pydata/numexpr.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=numexpr
PACKAGE_VERSION=${1:-v2.14.1}
PACKAGE_URL=https://github.com/pydata/numexpr.git

# Install dependencies
dnf install -y git python3.12 gcc gcc-c++ make wget openssl-devel \
    python3.12-devel python3.12-pip bzip2-devel libffi-devel \
    wget xz zlib-devel cmake openblas-devel

# Confirm python3.12 is available and meets the version requirement (>=3.10)
python3.12 --version

# Clone and checkout
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Remove the conflicting license field from pyproject.toml
sed -i '/^license = /d' pyproject.toml

# Install dependencies
python3.12 -m pip install pytest numpy

# Install package using python3.12 explicitly
if ! python3.12 -m pip install --python-version 3.12 -e . 2>/dev/null || ! python3.12 -m pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests using python3.12 explicitly
if ! python3.12 -m pytest numexpr/tests/ -v ; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi