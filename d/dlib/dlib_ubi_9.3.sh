#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : dlib
# Version       : v19.24.4
# Source repo   : https://github.com/davisking/dlib
# Tested on     : UBI: 9.3
# Language      : C++, Python
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

PACKAGE_NAME=dlib
PACKAGE_VERSION=${1:-v19.24.4}
PACKAGE_URL=https://github.com/davisking/dlib


yum install -y wget cmake unzip gcc gcc-c++ libX11-devel git python3-devel python3

python3 -m venv venv
source venv/bin/activate
pip install build pytest

# Clone package repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install
if ! python3 -m build --wheel ; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

# To install wheel run command "pip install dist/dlib-19.24.4-cp39-cp39-linux_ppc64le.whl"
# Replace the version as per your build

# Test
if ! python3 -m pytest --ignore docs --ignore dlib; then
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
