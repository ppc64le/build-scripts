#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: java-jwt
# Version	: 4.4.0
# Source repo	: https://github.com/auth0/java-jwt.git
# Tested on	: UBI: 8.7
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=java-jwt
PACKAGE_VERSION=${1:-4.4.0}
PACKAGE_URL=https://github.com/auth0/java-jwt.git
HOME_DIR=${PWD}

yum update -y
yum install -y git wget java-1.8.0-openjdk-devel java-11-openjdk-devel java-17-openjdk-devel tar lshw binutils nano

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Cloning java-jwt repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! ./gradlew clean build -x test; then
	echo "Build Fails"
	exit 1
elif ! ./gradlew test; then
	echo "Test Fails"
	exit 2
else
	echo "Build and Test Success"
	exit 0
fi