#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : spring-framework
# Version       : v6.0.19
# Source repo   : https://github.com/spring-projects/spring-framework.git
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

PACKAGE_NAME=spring-framework
PACKAGE_VERSION=${1:-v6.0.19}
PACKAGE_URL=https://github.com/spring-projects/spring-framework.git

# install tools and dependent packages
yum install -y git wget unzip

# setup java environment
yum install -y java-17-openjdk java-17-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

#Gradle Install
GRADLE_VERSION=gradle-8.2-rc-1
wget https://services.gradle.org/distributions/${GRADLE_VERSION}-bin.zip  && unzip -d /gradle /${GRADLE_VERSION}-bin.zip
export GRADLE_HOME=/gradle/${GRADLE_VERSION}/

# update the path env. variable
export PATH=${GRADLE_HOME}/bin:${PATH}

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
gradle clean build > /tmp/BUILD.log &
tail -c 3000 /tmp/BUILD.log | grep 'SUCCESS'
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
cat /tmp/BUILD.log
#Test
gradle test > /tmp/TEST.log &
tail -c 3000 /tmp/TEST.log | grep 'SUCCESS'
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0
