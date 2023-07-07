#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package	: pytest-virtualenv 
# Version	: v1.7.0
# Source repo	: https://github.com/man-group/pytest-plugins
# Tested on	: UBI: 8.5
# Language	: PHP
# Travis-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Abhishek Dighe <Abhishek.Dighe@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pytest-virtualenv
CORE_PACKAGE_NAME=python
PACKAGE_URL=https://github.com/man-group/pytest-plugins
CORE_PACKAGE_URL=https://github.com/man-group/pytest-plugins
PACKAGE_VERSION=${1:-v1.7.0}
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

echo "----------------Upgrading the System---------------------"
#dnf -y upgrade
dnf install -y git gcc python38 wget make python38-devel
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.8 get-pip.py

echo "----------------Installing the pre-requisite---------------------"
python3.8 -m pip install psutil
dnf install -y redhat-rpm-config libffi-devel openssl-devel cargo
python3.8 -m pip install cryptography --no-binary cryptography

if ! git clone $PACKAGE_URL; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | Github| Fail |  Clone_Fails" 
fi
cd pytest-plugins
git checkout $PACKAGE_VERSION
git merge ba81fc7e83b2fec0b5fefd876b1312eb433960e7
sed -i 's/pypandoc.convert/pypandoc.convert_file/g' common_setup.py
alias python=python3
make develop
cd pytest-virtualenv
if ! python3 setup.py install; then
	echo "------------------$PACKAGE_NAME:clone_success_but_build_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Clone_success_but_build_Fails"
	exit 1
fi

if ! python3 setup.py test ; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Install_success_but_test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Both_Install_and_Test_Success"
fi

