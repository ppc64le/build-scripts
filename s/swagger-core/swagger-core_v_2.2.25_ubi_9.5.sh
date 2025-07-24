#!/bin/bash -e
###############################################################################
#
# Package         : swagger-core
# Version         : v2.2.25
# Source repo     : https://github.com/swagger-api/swagger-core.git
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
PACKAGE_NAME="swagger-core"
MODULE_NAME="swagger-core"
MODULE_NAME2="swagger-models"
PACKAGE_VERSION="${1:-v2.2.25}"
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
export MAVEN_HOME=/opt/maven
export PATH=${MAVEN_HOME}/bin:$PATH

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
# Run Tests for swagger-core Module
# -------------------------------
cd "modules/swagger-core"
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${MODULE_NAME}: Tests Failed ------------------"
    exit 2
else
    echo "------------------ ${MODULE_NAME}: Tests Passed ------------------"
fi

# -------------------------------
# Run Tests for swagger-models Module
# -------------------------------
cd "../swagger-models"
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${MODULE_NAME2}: Tests Failed ------------------"
    exit 2
else
    echo "------------------ ${MODULE_NAME2}: Tests Passed ------------------"
fi
echo "PASS: ${MODULE_NAME} version $PACKAGE_VERSION built and tested successfully."
echo "PASS: ${MODULE_NAME2} version $PACKAGE_VERSION built and tested successfully."
exit 0
