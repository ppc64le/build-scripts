#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : aiosmtplib
# Version       : master
# Source repo   : https://github.com/cole/aiosmtplib.git
# Tested on     : UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=aiosmtplib
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/cole/aiosmtplib.git
yum install -y git zip gcc gcc-c++ rust-toolset python3-pytest.noarch \
	zlib-devel make python38 python38-devel python39 python39-devel \
	python2 openssl-devel python2-devel python3 python3-devel ncurses
	
ln -s /usr/bin/python3.8 /usr/bin/python
ln -s /usr/bin/pip3.8 /usr/bin/pip

pip install cython
pip install tox 
pip install rust

pip install lint
pip install clean
pip install docs
pip install click
   
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#observed that 3 tests are failing on both Power and Intel VMs.
tox
