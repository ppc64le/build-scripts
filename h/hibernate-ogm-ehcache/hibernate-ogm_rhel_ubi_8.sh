#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : hibernate-ogm-ehcache
# Version       : 5.2.0.Alpha1
# Source repo   : https://github.com/hibernate/hibernate-ogm-ehcache.git
# Tested on     : RHEL8
# Language      : java
# Travis-Check  : True
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

export REPO=https://github.com/hibernate/hibernate-ogm-ehcache.git

yum install rubygem-bundler -y
yum install -y java java-devel

yum update -y
yum install -y git wget

# install java
yum install -y java-1.8.0-openjdk-devel

# install maven
MAVEN_VERSION=3.6.3
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
ls /usr/local
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin
git clone ${REPO}
cd hibernate-ogm-ehcache
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit 1
fi



mvn -B -q -s settings-example.xml -Ptest -DskipTests=true -Dmaven.javadoc.skip=true -DskipDistro=true clean install
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build and test ..."
else
  echo  "Failed build and test......"
  exit
fi



