#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : logging-log4j2/log4j-api
# Version       : 2.8.2
# Source repo   : https://github.com/apache/logging-log4j2
# Tested on     : UBI: 8.4
# Language      : JAVA
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer's  : Apurva Agrawal<Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#Variables
REPO=https://github.com/apache/logging-log4j2
PKG_NAME=logging-log4j2/log4j-api/
PACKAGE_VERSION=${1:-log4j-2.8.2}

# Install required files
yum install -y git wget java-1.8.0-openjdk-devel

#install maven
cd /opt/
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
ln -s apache-maven-3.6.3 maven
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
mvn -version

#Clonning repo
git clone $REPO
cd $PKG_NAME
git checkout $PACKAGE_VERSION

#Build without tests
mvn clean package -DskipTests

#Run tests
mvn test
