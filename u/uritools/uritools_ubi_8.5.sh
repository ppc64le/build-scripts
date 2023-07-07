#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : uritools
# Version       : v3.0.0
# Source repo   : https://pypi.io/packages/source/u/uritools/uritools-3.0.0.tar.gz
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

PACKAGE_NAME=uritools
PACKAGE_VERSION=${1:-v3.0.0}

yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake wget

pip3 install tox

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Download the repo
wget https://pypi.io/packages/source/u/uritools/uritools-3.0.0.tar.gz
tar -xzf uritools-3.0.0.tar.gz

# Build and Test uritools 
cd uritools-3.0.0

if ! tox -e py36 ; then
	echo "------------------$PACKAGE_NAME:build_test_failure---------------------"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_test_success-------------------------"
	exit 0
fi