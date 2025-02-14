#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : jackson-modules-java8-datetime
# Version       : jackson-modules-java8-2.14.3
# Source repo   : https://github.com/FasterXML/jackson-modules-java8
# Tested on     : UBI 9.3
# Language      : Java,Logos
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : kotla santhosh<kotla.santhosh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

REPO_NAME="jackson-modules-java8"
PACKAGE_NAME="datetime"
PACKAGE_VERSION=${1:-jackson-modules-java8-2.14.3}
PACKAGE_URL="https://github.com/FasterXML/jackson-modules-java8.git"

# install tools and dependent packages
yum install -y git wget

# setup java environment
yum install -y java-11-openjdk-devel


# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

export M2_HOME=/usr/local/maven

# update the path env. variable
export PATH=$PATH:$M2_HOME/bin


# clone and checkout specified version
git clone $PACKAGE_URL
cd $REPO_NAME
git checkout $PACKAGE_VERSION
cd $PACKAGE_NAME

#Build
mvn install 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi


#Test
mvn test
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0
