#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : pyramid_debugtoolbar
# Version       : 4.12.1
# Source repo   : https://github.com/Pylons/pyramid_debugtoolbar
# Tested on     : UBI: 8.7
# Language      : JavaScript
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e


# Variables
export PACKAGE_VERSION=${1:-"4.12.1"}
export PACKAGE_NAME=pyramid_debugtoolbar
export PACKAGE_URL=https://github.com/Pylons/pyramid_debugtoolbar


# Install dependencies
yum install -y python3 git gcc-c++ python39-devel.ppc64le python3-setuptools python3-virtualenv python3-test 
pip3 install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
export TOXENV=py39
virtualenv -p python3 --system-site-packages env2 
/bin/bash -c "source env2/bin/activate"
pip3 install tox 
PATH=$PATH:/usr/local/bin/

# Build package
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(tox); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi