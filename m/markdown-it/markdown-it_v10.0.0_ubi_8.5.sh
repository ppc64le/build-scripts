#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: markdown-it
# Version	: v10.0.0
# Source repo	: https://github.com/markdown-it/markdown-it
# Tested on	: UBI: 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=markdown-it
PACKAGE_VERSION=${1:-10.0.0}
PACKAGE_URL=https://github.com/markdown-it/markdown-it

yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake

npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn

mkdir -p /home/tester

cd /home/tester
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! npm install; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_successful-------------------------------------"
        
fi


if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	exit 0
fi

