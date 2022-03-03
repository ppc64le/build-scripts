#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package 		: client-java-api
# Version 		: 6.0.1 / 8.0.0
# Source repo 	: https://github.com/kubernetes-client/java
# Tested on		: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


WORK_DIR=`pwd`

PACKAGE_NAME=java
PACKAGE_VERSION=${1:-client-java-parent-8.0.0}  
PACKAGE_URL=https://github.com/kubernetes-client/java.git

# Install required dependencies
yum install -y git maven java-1.8.0-openjdk-devel

#Clonning repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/

git checkout $PACKAGE_VERSION

cd kubernetes

#Build without tests
mvn install -DskipTests

#To execute tests
if ! mvn test ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
