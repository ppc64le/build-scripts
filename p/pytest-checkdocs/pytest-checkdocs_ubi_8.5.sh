#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : pytest-checkdocs
# Version       : v2.6.0
# Source repo   : https://github.com/jaraco/pytest-checkdocs
# Tested on     : UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas / Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pytest-checkdocs
PACKAGE_VERSION=${1:-v2.6.0}
PACKAGE_URL=https://github.com/jaraco/pytest-checkdocs

yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

pip3 install setuptools==59.6.0
pip3 install wheel

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Clone_Fails" 
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 setup.py install

if ! python3 setup.py test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
fi