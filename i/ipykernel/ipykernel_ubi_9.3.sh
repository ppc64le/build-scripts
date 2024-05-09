#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ipykernel
# Version       : v6.29.4
# Source repo   : https://github.com/ipython/ipykernel
# Tested on     : UBI: 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ipykernel
PACKAGE_VERSION=${1:-v6.29.4}
PACKAGE_URL=https://github.com/ipython/ipykernel

yum install -y cmake make git python3.11  python3.11-devel python3.11-pip python3.11-pytest gcc-c++
python3.11 -m pip install trio pytest flaky jupyter-client

# Clone package repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install
if ! python3.11 -m pip install .; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

python3.11 -m pip install -e ".[test]"

# Test
if ! python3.11 -m pytest -vv -s --cov ipykernel --cov-branch --cov-report term-missing:skip-covered --durations 10; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi
