#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: python-bunyan
# Version	: 5e41d89
# Source repo   : https://github.com/complyue/python-bunyan.git
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Reynold Vaz <Reynold.Vaz@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=python-bunyan
PACKAGE_VERSION=${1:-5e41d89}
PACKAGE_URL=https://github.com/complyue/python-bunyan.git

yum install -y python36 git

mkdir -p /home/tester && cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | Fail |  Clone_Fails" 
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install bunyan
pip3 install -r dev-requirements.txt
pip3 install -r requirements.txt

if ! nosetests tests; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Fail |  Install_success_but_test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Pass |  Both_Install_and_Test_Success"
fi 