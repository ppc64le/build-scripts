# ----------------------------------------------------------------------------
#
# Package       : hibernate-ogm-ehcache
# Version       : 5.2.0.Alpha1
# Source repo   : https://github.com/hibernate/hibernate-ogm-ehcache.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Ankit Paraskar <ankit.paraskar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export REPO=https://github.com/hibernate/hibernate-ogm-ehcache.git

sudo yum install rubygem-bundler
sudo yum install -y java java-devel

sudo yum update -y
sudo yum install -y git wget

# install java
sudo yum install -y java-1.8.0-openjdk-devel

# install maven
MAVEN_VERSION=3.6.3
sudo wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
sudo ls /usr/local
sudo tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
sudo mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
sudo ls /usr/local
sudo rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin


git clone ${REPO}
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

cd hibernate-ogm-ehcache

mvn -B -q -s settings-example.xml -Ptest -DskipTests=true -Dmaven.javadoc.skip=true -DskipDistro=true clean install
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build and test ..."
else
  echo  "Failed build and test......"
  exit
fi



