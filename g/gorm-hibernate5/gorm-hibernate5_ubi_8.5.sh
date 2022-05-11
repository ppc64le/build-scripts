#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : gorm-hibernate5
# Version       : v6.1.12
# Source repo	: https://github.com/grails/gorm-hibernate5
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas r <Valen.Mascarenhas@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=gorm-hibernate5
PACKAGE_VERSION=${1:-v6.1.12}
PACKAGE_URL=https://github.com/grails/gorm-hibernate5

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

yum install git unzip wget maven -y

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git apply $SCRIPT_DIR/patchfiles/patchfile

chmod u+x ./gradlew

if ! ./gradlew install; then
	echo "------------------Build_Install_fails---------------------"
	exit 1
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

if ! ./gradlew test; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi