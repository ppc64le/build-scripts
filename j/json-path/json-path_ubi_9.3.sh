#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : JsonPath
# Version       : 2.9.0
# Source repo   : https://github.com/json-path/JsonPath
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=JsonPath
PACKAGE_VERSION=${1:-json-path-2.9.0}
PACKAGE_URL=https://github.com/json-path/JsonPath

# install tools and dependent packages
yum install -y git wget

# setup java environment
yum install -y java java-devel unzip

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin


#install gradle
wget https://services.gradle.org/distributions/gradle-7.2-rc-1-bin.zip -P /tmp && unzip -d /gradle /tmp/gradle-7.2-rc-1-bin.zip
export GRADLE_HOME=/gradle/gradle-7.2-rc-1/

# update the path env. variable
export PATH=${GRADLE_HOME}/bin:${PATH}


# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
./gradlew build 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi


#Test
./gradlew check
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0
