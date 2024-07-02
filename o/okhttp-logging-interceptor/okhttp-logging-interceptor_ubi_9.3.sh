#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : okhttp-logging-interceptor
# Version       : 4.10.0
# Source repo   : https://github.com/square/okhttp
# Tested on     : UBI 9.3
# Language      : Kotlin,Others
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

REPO_NAME="okhttp"
PACKAGE_NAME="okhttp/okhttp-logging-interceptor"
PACKAGE_VERSION=${1:-parent-4.10.0}
PACKAGE_URL="https://github.com/square/okhttp.git"

# install tools and dependent packages
yum install -y git wget unzip 

# setup java environment
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH



#install gradle
wget https://services.gradle.org/distributions/gradle-7.2-rc-1-bin.zip -P /tmp && unzip -d /gradle /tmp/gradle-7.2-rc-1-bin.zip
export GRADLE_HOME=/gradle/gradle-7.2-rc-1
  
# update the path env. variable
export PATH=${GRADLE_HOME}/bin:${PATH}
  
  
# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
  
#Build
gradle build 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
  

#Test
gradle test
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0
