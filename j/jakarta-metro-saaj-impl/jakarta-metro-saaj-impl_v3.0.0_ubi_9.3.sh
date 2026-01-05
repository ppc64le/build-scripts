#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : metro-saaj (Jakarta SOAP Implementation (SAAJ))
# Version       : 3.0.0
# Source repo   : https://github.com/eclipse-ee4j/metro-saaj
# Tested on     : UBI 9.3 (ppc64le)
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

# -------------------------------
# Configuration & Initialization
# -------------------------------
PACKAGE_NAME=metro-saaj
PACKAGE_VERSION=${1:-3.0.0}
PACKAGE_URL=https://github.com/eclipse-ee4j/metro-saaj
BUILD_HOME=$(pwd)

# -------------------------------
# Install required tools and dependencies
# -------------------------------
yum install -y git wget tar java-17-openjdk-devel glibc-locale-source glibc-langpack-en

# Setup java environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Install Maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

# Ensure the UTF-8 locale is available and set
localedef -c -i en_US -f UTF-8 en_US.UTF-8 || true
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Setup Maven environment
export MVN_HOME=/usr/local/maven
export MAVEN_OPTS="-Dfile.encoding=UTF-8"

# Setup env path java + maven
export PATH=$PATH:$JAVA_HOME/bin:$MVN_HOME/bin

# Clone and checkout specified version
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# -------------------------
# Build the package
# -------------------------
ret=0
mvn -B -ff -ntp clean install -DskipTests || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "SUCCESS: $PACKAGE_NAME - Build completed successfully."
fi

# -------------------------
# Test
# -------------------------
mvn -B -ff -ntp test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Tests failed."
    exit 2
else
    echo "SUCCESS: $PACKAGE_NAME - All tests passed successfully."
fi

# -------------------------
# Smoke Test
# -------------------------
BUILT_JAR=$(find . -path '*/target/*.jar' -type f ! -name '*sources.jar' ! -name '*javadoc.jar' | head -n1)
if [ -z "$BUILT_JAR" ]; then
    echo "ERROR: $PACKAGE_NAME - Build succeeded but no JAR file found in any target/ directory."
    exit 2
else 
    echo "SUCCESS: Jakarta-${PACKAGE_NAME}-impl - JAR built successfully for $PACKAGE_VERSION : $(basename "$BUILT_JAR")"
    exit 0
fi
