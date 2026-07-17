#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numexpr
# Version       : v2.14.1
# Source repo   : https://github.com/pydata/numexpr.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
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

#variables
PACKAGE_NAME=numexpr
PACKAGE_VERSION=${1:-v2.14.1}
PACKAGE_URL=https://github.com/pydata/numexpr.git
PACKAGE_DIR=./numexpr

# Install dependencies and tools.
dnf install -y git gcc gcc-c++ make wget openssl-devel python3.12-devel python3.12-pip bzip2-devel libffi-devel wget xz zlib-devel cmake openblas-devel

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i 's/^license = "MIT"/license = {text = "MIT"}/' pyproject.toml
sed -i '/^license-files/d' pyproject.toml

#install pytest
python3.12 -m pip install pytest

python3.12 -m pip install numpy
python3.12 -m pip install "setuptools<68" wheel --upgrade
python3.12 -m pip install -e . --no-build-isolation
python3.12 -m pip install tox

#install
if ! (python3.12 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! (python3.12 -m pytest numexpr/tests/); then
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
