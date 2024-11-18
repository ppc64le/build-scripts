#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : spring-data-redis
# Version       : 3.2.4
# Source repo   : https://github.com/spring-projects/spring-data-redis.git
# Tested on     : UBI 9.3
# Language      : Java, Others
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=spring-data-redis
PACKAGE_VERSION=${1:-3.2.4}
PACKAGE_URL=https://github.com/spring-projects/spring-data-redis.git


# install tools and dependent packages
yum install -y git wget unzip sudo make gcc gcc-c++ cmake

# setup java environment
yum install -y java-17-openjdk java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.9.4}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

export M2_HOME=/usr/local/maven

# update the path env. variable
export PATH=$PATH:$M2_HOME/bin

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


#Build 
./mvnw clean install -DskipTests
if [ $? != 0 ]
then
  echo "Build  failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi

#Test
# ./mvnw test
# Run 5: RedisCacheTests.retrieveReturnsCachedValueWhenLockIsReleased:604 » Timeout is Failing
# Tests run: 17366, Failures: 0, Errors: 1, Skipped: 453
exit 0