#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jackson-core
# Version       : jackson-core-2.17.2
# Source repo   : https://github.com/FasterXML/jackson-core
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
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

PACKAGE_NAME=jackson-core
PACKAGE_VERSION=${1:-jackson-core-2.17.2}
PACKAGE_URL=https://github.com/FasterXML/jackson-core
BUILD_HOME=$(pwd)

# Install tools and dependent packages
yum install -y git wget java-17-openjdk-devel

# setup java environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

# setup maven environment
export MVN_HOME=/usr/local/maven

# update the path env. variable - Java + Maven
export PATH=$PATH:$JAVA_HOME/bin:$MVN_HOME/bin

# clone and checkout specified version
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# -------------------------
# Build
# -------------------------
ret=0
./mvnw -B -ff -ntp clean install -DskipTests || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "SUCCESS: $PACKAGE_NAME - Build completed successfully."
fi

# -------------------------
# Test
# -------------------------
./mvnw -B -ff -ntp test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Tests failed."
    exit 2
else
    echo "SUCCESS: $PACKAGE_NAME - All tests passed successfully."
fi

# Smoke Test
BUILT_JAR=$(ls target/*.jar 2>/dev/null | head -n1)

if [ -z "$BUILT_JAR" ]; then
    echo "ERROR: $PACKAGE_NAME - Build succeeded but no JAR file was found in the target/ directory."
    exit 2
else 
    echo "SUCCESS: $PACKAGE_NAME - JAR built successfully for $PACKAGE_VERSION : $(basename "$BUILT_JAR")"
	exit 0
fi
