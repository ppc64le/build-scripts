#!/bin/bash -e
###############################################################################
#
# Package         : swagger-parser
# Version         : v1.0.71
# Source repo     : https://github.com/swagger-api/swagger-parser.git
# Language        : Java
# Tested on       : UBI 9.5 (ppc64le)
# Travis-Check    : True
# Maintainer      : Amit Kumar <amit.kumar282@ibm.com>
# License         : Apache License, Version 2.0 or later
#
# Disclaimer      : This script has been tested in root mode on the specified
#                   platform using the stated version. It may not work as 
#                   expected with newer versions or different environments.
#
###############################################################################

# -------------------------------
# Configuration & Initialization
# -------------------------------
PACKAGE_NAME="swagger-parser"
PACKAGE_VERSION="${1:-v1.0.71}"
PACKAGE_URL="https://github.com/swagger-api/${PACKAGE_NAME}.git"
BUILD_HOME="$(pwd)"

# -------------------------------
# Install Dependencies
# -------------------------------
yum install -y git java-1.8.0-openjdk java-1.8.0-openjdk-devel wget

# Set Java 8
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Install Maven
MAVEN_VERSION=3.9.6
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
ln -s apache-maven-${MAVEN_VERSION} maven
export MAVEN_HOME=/opt/maven
export PATH=${MAVEN_HOME}/bin:$PATH

echo "Using Maven version: $(mvn -v)"

# -------------------------------
# Clone Repository
# -------------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# -------------------------------
# Build the Package
# -------------------------------
ret=0
mvn clean install -DskipTests=true -Dmaven.javadoc.skip=true || ret=$?
if [ $ret -ne 0 ]; then
   echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
   exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Build Passed ------------------"
fi

# -------------------------------
# Run Tests for swagger-parser
# -------------------------------
mvn surefire:test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}: Tests Failed ------------------"
    exit 2
else
    echo "------------------ ${PACKAGE_NAME}: Tests Passed ------------------"
fi

echo "PASS: ${PACKAGE_NAME} version $PACKAGE_VERSION built and tested successfully."
exit 0
