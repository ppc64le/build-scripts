#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : glassfish-hk2-extra
# Version       : 1.0.3-RELEASE
# Source repo   : https://github.com/eclipse-ee4j/glassfish-hk2-extra.git
# Tested on     : UBI 9.3
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=glassfish-hk2-extra
PACKAGE_VERSION=${1:-1.0.3}
PACKAGE_URL=https://github.com/eclipse-ee4j/${PACKAGE_NAME}.git
PACKAGE_DIR_NAME=osgi-resource-locator
BUILD_HOME=$(pwd)

# Install tools and dependent packages
yum install -y git wget java-17-openjdk-devel

# Setup Java environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Install Maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

# Setup Maven environment
export MVN_HOME=/usr/local/maven

# update the path env. variable - Java + Maven
export PATH=$PATH:$JAVA_HOME/bin:$MVN_HOME/bin

# Clone and checkout the specified version
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}-RELEASE

# Update source/target versions if necessary, to avoid build errors
cd $PACKAGE_DIR_NAME
sed -i 's/<source>1\.6<\/source>/<source>1.8<\/source>/g' pom.xml
sed -i 's/<target>1\.6<\/target>/<target>1.8<\/target>/g' pom.xml

# Build
ret=0
mvn -B -ntp clean compile -Dgpg.skip || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Build  failed."
    exit 1
fi

# Test
mvn -B -ntp test -Dgpg.skip || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Test phase failed."
    exit 1
fi

# Smoke Test
TARGET_PATH="/opt/$PACKAGE_NAME/${PACKAGE_DIR_NAME}/target"
JAR_FILE="$TARGET_PATH/${PACKAGE_DIR_NAME}-${PACKAGE_VERSION}.jar"
JAVADOC_JAR="$TARGET_PATH/${PACKAGE_DIR_NAME}-${PACKAGE_VERSION}-javadoc.jar"

echo "Main JAR file    : $JAR_FILE"
echo "Javadoc JAR file : $JAVADOC_JAR"
echo "PASS : Successfully built and tested the $PACKAGE_NAME-$PACKAGE_VERSION-RELEASE"
