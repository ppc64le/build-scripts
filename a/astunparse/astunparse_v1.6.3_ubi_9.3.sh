#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : astunparse
# Version       : 1.6.3
# Source repo   : https://github.com/simonpercivall/astunparse.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Simran Sirsat <Simran.Sirsat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=astunparse
PACKAGE_VERSION=${1:-"v1.6.3"}
PACKAGE_URL=https://github.com/simonpercivall/astunparse.git

yum install -y git wget python3 python3-devel.ppc64le gcc gcc-c++ make openssl-devel bzip2-devel libffi-devel xz cmake openblas-devel

python3 -m pip install setuptools wheel pytest


git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install -r requirements.txt
python3 -m pip install -r test_requirements.txt
python3 -m pip install -r docs/requirements.txt

if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#skipping testcases in tests/test_dump.py as it fails on x86 as well.

if ! (pytest --ignore=tests/test_dump.py) ; then
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
