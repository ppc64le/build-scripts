#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package 		: xml-path
# Version 		: 3.3.0 / 4.4.0
# Source repo 	: https://github.com/rest-assured/rest-assured/
# Tested on		: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> / <Vaibhav.Nazare@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

WORK_DIR=`pwd`

PACKAGE_NAME=rest-assured
PACKAGE_VERSION=${1:-rest-assured-3.3.0}  
PACKAGE_URL=https://github.com/rest-assured/rest-assured.git

# Install required dependencies
yum install -y git maven java-1.8.0-openjdk-devel

#Clonning repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/

git checkout $PACKAGE_VERSION

cd xml-path

#Build without tests
mvn install -DskipTests

#To execute tests
if ! mvn test ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
