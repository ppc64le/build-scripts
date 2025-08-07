#!/bin/bash -e
###############################################################################
#
# Package         : swagger-core/swagger-models
# Version         : v1.6.14
# Source repo     : https://github.com/swagger-api/swagger-core.git
# Language        : Java
# Tested on       : UBI 9.3 (ppc64le)
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
PACKAGE_NAME="swagger-core"
MODULE_NAME="swagger-models"
PACKAGE_VERSION="${1:-v1.6.14}"
PACKAGE_URL="https://github.com/swagger-api/swagger-core.git"
BUILD_HOME="$(pwd)"

# -------------------------------
# Install Dependencies
# -------------------------------
yum install -y git java-17-openjdk java-17-openjdk-devel wget

# Install Maven
MAVEN_VERSION=3.9.6
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
ln -s apache-maven-${MAVEN_VERSION} maven

# Set Java 17 environment variables
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
# Set Maven environment variables
export MAVEN_HOME=/opt/maven

# Update PATH to include both Java and Maven
export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

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
mvn clean install -DskipTests || ret=$?
if [ $ret -ne 0 ]; then
   echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
   exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Build Passed ------------------"
fi

# -------------------------------
# Run Tests for swagger-models Module
# -------------------------------
cd "modules/swagger-models"
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${MODULE_NAME2}: Tests Failed ------------------"
    exit 2
else
    echo "------------------ ${MODULE_NAME2}: Tests Passed ------------------"
fi
echo "PASS: ${MODULE_NAME} version $PACKAGE_VERSION built and tested successfully."
exit 0
