#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : nbconvert
# Version       : v7.7.3, v7.12.0
# Source repo   : https://github.com/jupyter/nbconvert
# Tested on     : UBI 8.7
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=nbconvert
PACKAGE_VERSION=${1:-v7.12.0}
PACKAGE_URL=https://github.com/jupyter/nbconvert
HOME_DIR=${PWD}

yum install -y git python3.11 python3.11-devel gcc-c++

# Install pip and activate venv
python3 -m ensurepip --upgrade
export PATH=$PATH:/usr/local/bin

# Clone package repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install jupyter
export JUPYTER_PLATFORM_DIRS=1
jupyter --paths


# Install
if !  python3 -m pip install -e .; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

# Test
python3 -m pip install nbconvert[test]
if ! pytest; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi