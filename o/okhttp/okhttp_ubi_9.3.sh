#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : okhttp
# Version       : parent-4.12.0
# Source repo   : https://github.com/square/okhttp
# Tested on     : UBI 9.3
# Language      : Kotlin,Others
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

PACKAGE_NAME="okhttp"
PACKAGE_VERSION=${1:-parent-4.12.0}
PACKAGE_URL="https://github.com/square/okhttp.git"

# install tools and dependent packages
yum install -y git wget unzip sudo

# setup java environment
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
  
# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sudo bash -c "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts" 
#Build
./gradlew clean build
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
  
  
#Test
./gradlew test
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0
