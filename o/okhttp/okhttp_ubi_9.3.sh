#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : okhttp
# Version       : parent-4.12.0
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

PACKAGE_NAME="okhttp"
PACKAGE_VERSION=${1:-parent-4.12.0}
PACKAGE_URL="https://github.com/square/okhttp.git"

# install tools and dependent packages
yum install -y git wget unzip 

# setup java environment
# yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless

# # setup java environment
# export JAVA_HOME=$(compgen -G '/usr/lib/jvm/jre-1.8.0-openjdk-*')

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export JAVA_OPTS="-Xms2048M -Xmx4096M -XX:MaxPermSize=4096M"
# export LANG="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build

if ! ./gradlew clean build ; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
       exit 1
fi

sudo bash -c "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts"
if ! ./gradlew test -Dtest.java.version=11 -Dorg.gradle.jvmargs=-Xmx4g -Dorg.gradle.daemon=false -Dkotlin.incremental=false -Dtest.ipv6=true ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Both_Build_and_Test_Fail"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
