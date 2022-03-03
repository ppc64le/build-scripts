#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : scaffolding
# Version       : v4.0.0
# Source repo	: https://github.com/grails/scaffolding.git
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vikas Kumar <kumar.vikas@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scaffolding
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v4.0.0}
PACKAGE_URL=https://github.com/grails/scaffolding.git

yum install -y git java-1.8.0-openjdk-devel

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 0
fi

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./gradlew build -Dgeb.env=chromeHeadless; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! ./gradlew check -Dgeb.env=chromeHeadless; then
	echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
	exit 0
fi
