#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: type-parser
# Version	: type-parser-0.8.1
# Source repo	: https://github.com/drapostolos/type-parser.git
# Tested on	: UBI: 8.5
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

PACKAGE_NAME=type-parser
PACKAGE_VERSION=${1:-type-parser-0.8.1}
PACKAGE_URL=https://github.com/drapostolos/type-parser.git
HOME_DIR=${PWD}

yum update -y
yum install -y git wget tar java-11-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Cloning type-parser repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

chmod +x gradlew
chmod +x gradle/wrapper/gradle-wrapper.jar

#Building type-parser
if ! ./gradlew clean build; then
        echo "Build Fails"
		exit 1
fi

#Test type-parser
if ! ./gradlew test; then
        echo "Test Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi