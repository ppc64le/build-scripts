#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: vertx-json-schema
# Version	: 4.0.1
# Source repo	: https://github.com/eclipse-vertx/vertx-json-schema
# Tested on	: ubi 8.5
# Language      : java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="vertx-json-schema"
PACKAGE_VERSION=${1:-"4.0.1"}
PACKAGE_URL="https://github.com/eclipse-vertx/vertx-json-schema"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

echo "insstalling dependencies from system repo..."
dnf install -qy git maven

echo "cloning..."
if ! git clone -q $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
mvn compile 
if ! mvn install; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! mvn test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
