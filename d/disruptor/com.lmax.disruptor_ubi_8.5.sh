#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : disruptor
# Version       : master
# Source repo   : https://github.com/LMAX-Exchange/disruptor.git
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=disruptor
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/LMAX-Exchange/disruptor.git
GRADLE_VERSION=7.1.1
yum install -y git wget unzip java-11-openjdk-devel

#install gradle
wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip
unzip gradle-$GRADLE_VERSION-bin.zip
mkdir /opt/gradle
cp -pr gradle-$GRADLE_VERSION/* /opt/gradle
export PATH=/opt/gradle/bin:${PATH}

#clone the package

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package.
./gradlew build
./gradlew test
