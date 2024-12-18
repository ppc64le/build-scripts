#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : thrift-java
# Version       : v0.20.0
# Source repo   : https://github.com/apache/thrift.git
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e

#Variables
REPO=https://github.com/apache/thrift.git

# Default tag for asm
if [ -z "$1" ]; then
  export VERSION="v0.20.0"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget unzip 

#Install temurin java17
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
tar -C /usr/local -zxf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
export JAVA_HOME=/usr/local/jdk-17.0.9+9
export JAVA17_HOME=/usr/local/jdk-17.0.9+9
export PATH=$PATH:/usr/local/jdk-17.0.9+9/bin
ln -sf /usr/local/jdk-17.0.9+9/bin/java /usr/bin
rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz

export GRADLE_VERSION="8.0.2"
# download gradle distribution
wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip -q -O /tmp/gradle-$GRADLE_VERSION-bin.zip

# unzip and install
unzip -d /tmp /tmp/gradle-$GRADLE_VERSION-bin.zip
mv /tmp/gradle-$GRADLE_VERSION /usr/local/gradle
ln -s /usr/local/gradle/bin/gradle /usr/local/bin


#Cloning Repo
git clone $REPO
cd thrift
git checkout ${VERSION}
cd lib/java/
#Build and test package
if ! gradle assemble ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

exit 0
