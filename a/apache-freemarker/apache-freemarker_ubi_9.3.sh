#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : freemarker
# Version          : v2.3.33
# Source repo      : https://github.com/apache/freemarker.git
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=freemarker
PACKAGE_URL=https://github.com/apache/freemarker.git
PACKAGE_VERSION=${1:-v2.3.33}

# Install dependencies
yum install -y git wget gcc-c++ gcc 
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-17-openjdk java-17-openjdk-devel 
 
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin
 
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin
 
# Install Java16
wget https://github.com/adoptium/temurin16-binaries/releases/download/jdk-16.0.2%2B7/OpenJDK16U-jdk_ppc64le_linux_hotspot_16.0.2_7.tar.gz
tar -C /usr/local -zxf OpenJDK16U-jdk_ppc64le_linux_hotspot_16.0.2_7.tar.gz
export JAVA_HOME_16=/usr/local/jdk-16.0.2+7
export PATH=$PATH:$JAVA_HOME_16/bin
ln -sf $JAVA_HOME_16/bin/java /usr/bin/java16
rm -rf OpenJDK16U-jdk_ppc64le_linux_hotspot_16.0.2_7.tar.gz
 
# Install Java9
wget https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk-9.0.4%2B11/OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz
tar -C /usr/local -zxf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz
export JAVA_HOME_9=/usr/local/jdk-9.0.4+11
export PATH=$PATH:$JAVA_HOME_9/bin
ln -sf $JAVA_HOME_9/bin/java /usr/bin/java9
rm -rf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz

wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/a/apache-freemarker/toolchains.xml
mkdir ~/.m2
cp toolchains.xml ~/.m2/

#clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
if ! ./gradlew "-Pfreemarker.signMethod=none" "-Pfreemarker.allowUnsignedReleaseBuild=true" --continue clean build ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
if ! ./gradlew "-Pfreemarker.signMethod=none" "-Pfreemarker.allowUnsignedReleaseBuild=true" check; then
    echo "------------------$PACKAGE_NAME:Build_success_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Build_Success_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

