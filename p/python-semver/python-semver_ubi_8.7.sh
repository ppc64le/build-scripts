#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : python-semver
# Version	    : 3.0.1
# Source repo	    : https://github.com/python-semver/python-semver
# Tested on	    : ubi 8.7
# Language          : Python
# Travis-Check      : true
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="python-semver"
PACKAGE_VERSION=${1:-"3.0.1"}
PACKAGE_URL=https://github.com/python-semver/python-semver

#Install dependencies
#yum -y update
yum install -y yum-utils git gcc gcc-c++ make 

#Installing Python 3.9
yum install python39 python39-devel -y 

#clone the repository
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Install dependencies
python3 -m pip install --upgrade pip
python3 -m pip install tox tox-gh-actions

#Build the package
if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#Test with tox
if ! python3 -m tox; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  both_build_and_test_success"
    exit 0
fi

