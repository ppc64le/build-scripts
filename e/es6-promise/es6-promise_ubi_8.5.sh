#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: es6-promise
# Version	: v4.2.8
# Source repo	: https://github.com/stefanpenner/es6-promise.git
# Tested on	: ubi 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: sachin.kakatkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./es6-promise_ubi_8.5.sh v4.2.8

PACKAGE_NAME=es6-promise
PACKAGE_VERSION=$1
PACKAGE_URL=https://github.com/stefanpenner/es6-promise.git

if [ -z "$1" ]
  then
    PACKAGE_VERSION=v4.2.8
fi

dnf install git npm wget bzip2 fontconfig jq -y

wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -sf $pwd/phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
phantomjs -v

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Remove older package if any
rm -rf $PACKAGE_NAME

#Clone the package
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
PACKAGE_VERSION=$(jq -r ".version" package.json)

#Install package and dependency
if ! npm install && npm audit fix && npm audit fix --force; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

#Run the test cases
cd /home/tester/$PACKAGE_NAME
if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
