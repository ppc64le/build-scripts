#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: nltk
# Version	: develop
# Source repo	: https://github.com/nltk/nltk
# Tested on	: UBI: 8.5
# Language      : Python
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=nltk
PACKAGE_VERSION=${1:-develop}
PACKAGE_URL=https://github.com/nltk/nltk

yum install -y sudo
sudo yum -y update && sudo yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake libjpeg-devel atlas atlas-devel lapack-devel blas-devel

sudo pip3.8 install cython
sudo pip3.8 install nltk
sudo pip3.8 install tox

git clone $PACKAGE_URL
cd $PACKAGE_NAME
sudo pip3.8 install -r pip-req.txt
sudo python3.8 -m nltk.downloader all

if ! tox -e py38; then
	echo "------------------Build_Test_fails---------------------"
	exit 1
else
	echo "------------------Build_Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi
