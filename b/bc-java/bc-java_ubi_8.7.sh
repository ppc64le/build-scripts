#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: bc-java
# Version	: r1rv73
# Source repo	: https://github.com/bcgit/bc-java.git
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

PACKAGE_NAME=bc-java
PACKAGE_VERSION=${1:-r1rv73}
PACKAGE_URL=https://github.com/bcgit/bc-java.git
HOME_DIR=${PWD}

yum update -y
yum install -y git wget tar java-11-openjdk-devel unzip openssl-devel

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Install Gradle tool
cd $HOME_DIR
wget https://services.gradle.org/distributions/gradle-7.6.1-bin.zip
unzip gradle-7.6.1-bin.zip
mkdir /opt/gradle
cp -pr gradle-7.6.1/* /opt/gradle
export PATH=/opt/gradle/bin:${PATH}

#Cloning bc-java repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Cloning bc-test-data repo required for running tests
cd $HOME_DIR
git clone https://github.com/bcgit/bc-test-data.git

cd $HOME_DIR/bc-java
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

if ! gradle clean build -x test; then
        echo "Build Fails"
		exit 1

# The :tls:test has been observed to fail on both ppc64le and x86_64 platforms during the execution of the test suite on UBI but works well on Ubuntu. Therefore, it has been excluded from the test suite run.
# Raised issue for the same - https://github.com/bcgit/bc-java/issues/1382

elif ! gradle test -x :tls:test; then
        echo "Test Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi