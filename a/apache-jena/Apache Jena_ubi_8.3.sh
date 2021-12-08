# ----------------------------------------------------------------------------
#
# Package       : Apache Jena
# Version       : 4.1.0
# Source repo   : https://github.com/apache/jena
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
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
REPO=https://github.com/apache/jena

# Default tag Apache Jena
if [ -z "$1" ]; then
  export VERSION="4.1.0"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget

# install java
yum install -y java-11-openjdk-devel

# install maven
MAVEN_VERSION=3.8.1
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
ls /usr/local
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven
# update the path env. variable 
export PATH=$PATH:$M2_HOME/bin

#Cloning Repo
git clone $REPO
cd ./jena/apache-jena
git checkout ${VERSION}

#Build and test package
mvn clean install -DskipTests
mvn test





