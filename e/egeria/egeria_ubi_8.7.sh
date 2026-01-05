#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: egeria
# Version	: V4.0
# Source repo	: https://github.com/odpi/egeria.git
# Tested on	: UBI: 8.7
# Language      : Java
# Ci-Check  : True
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

PACKAGE_NAME=egeria
PACKAGE_VERSION=${1:-V4.0}
PACKAGE_URL=https://github.com/odpi/egeria.git
HOME_DIR=${PWD}

yum update -y
yum install -y git wget tar java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Cloning egeria repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! ./gradlew build; then
        echo "Build Fails"
	exit 1
elif ! ./gradlew test; then
        echo "Test Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi