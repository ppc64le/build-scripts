#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : micrometer-observation
# Version       : v1.10.13
# Source repo   : https://github.com/micrometer-metrics/micrometer
# Tested on     : UBI 9.3
# Language      : Java,Others
# Ci-Check  : True
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
REPO_NAME="micrometer"
PACKAGE_NAME="micrometer-observation"
PACKAGE_VERSION=${1:-v1.10.13}
PACKAGE_URL="https://github.com/micrometer-metrics/micrometer.git"

# install tools and dependent packages
yum install -y git wget unzip 

# setup java environment
yum install -y java-11-openjdk java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

#install Gradle
GRADLE_VERSION=gradle-8.2-rc-1
export WORK_DIR=`pwd`
export HOME=$WORK_DIR
wget https://services.gradle.org/distributions/${GRADLE_VERSION}-all.zip -P /tmp && unzip -d $WORK_DIR/gradle /tmp/${GRADLE_VERSION}-all.zip
export GRADLE_HOME=$WORK_DIR/gradle/${GRADLE_VERSION}/
export PATH=${GRADLE_HOME}/bin:${PATH}
  
# clone and checkout specified version
git clone $PACKAGE_URL
cd $REPO_NAME
git checkout $PACKAGE_VERSION
cd $PACKAGE_NAME

#Build
gradle build 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
    
#Test
gradle check
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0
