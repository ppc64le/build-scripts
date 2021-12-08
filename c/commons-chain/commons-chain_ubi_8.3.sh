# ----------------------------------------------------------------------------
#
# Package       : commons-chain
# Version       : 1.2
# Source repo   : https://github.com/apache/commons-chain
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Jotirling Swami <Jotirling.Swami1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Variables
REPO=https://github.com/apache/commons-chain.git
VERSION=CHAIN_1_2
DIR=commons-chain

# install tools and dependent packages
yum update -y
yum install -y git wget


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

# Cloning the repository from remote to local
cd /home
git clone $REPO
cd $DIR
git checkout $VERSION

#Build without tests
mvn clean package -DskipTests

#Run tests
mvn test