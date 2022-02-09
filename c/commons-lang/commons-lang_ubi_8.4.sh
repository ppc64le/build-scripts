#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : commons-lang
# Version       : 3.7, 3.8.1
# Source repo   : https://github.com/apache/commons-lang.git
# Tested on     : UBI: 8.4
# Language      : JAVA
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer's  : Jotirling Swami <Jotirling.Swami1@ibm.com>, Apurva Agrawal<Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#Variables
REPO=https://github.com/apache/commons-lang.git
PACKAGE_VERSION=LANG_3_7


echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is LANG_3_1 "

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"


# Install required files
yum -y install git wget

# install java
yum -y install java-1.8.0-openjdk-devel

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
cd commons-lang
git checkout $PACKAGE_VERSION

#Build without tests
mvn clean package -DskipTests

#Run tests
mvn test
