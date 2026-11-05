#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : msgspec
# Version          : 0.22.0
# Source repo      : https://github.com/msgspec/msgspec
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=msgspec
PACKAGE_VERSION=${1:-0.22.0}
PACKAGE_URL=https://github.com/msgspec/msgspec
PACKAGE_DIR=msgspec

# Needs Python >= 3.10 and a C compiler for the extension
dnf install -y git gcc gcc-c++ make python3.12 python3.12-pip python3.12-devel

# Clone the repository (git tags are needed by setuptools-scm)
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Test deps from the test-unit group (the unit tests skip anything missing)
python3.12 -m pip install --upgrade pip "setuptools>=80" "setuptools-scm>=8" wheel build
python3.12 -m pip install "pytest>=9" attrs msgpack pyyaml tomli-w typing-extensions

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Failed"
    exit 1
fi

# Run the unit tests only (tests/prof needs codspeed and memray)
if ! python3.12 -m pytest tests/unit ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
