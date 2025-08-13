#!/bin/bash -e
###############################################################################
#
# Package         : swagger-parser
# Version         : v2.1.22
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
MODULE_NAME1="swagger-parser-core"
MODULE_NAME2="swagger-parser-v3"
PACKAGE_VERSION="${1:-v2.1.22}"
PACKAGE_URL="https://github.com/swagger-api/${PACKAGE_NAME}.git"
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
mvn clean install -Dmaven.javadoc.skip=true -DskipTests || ret=$?
if [ $ret -ne 0 ]; then
   echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
   exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Build Passed ------------------"
fi

# -------------------------------
# Run Tests for swagger-parser-core Module
# -------------------------------
cd "modules/swagger-parser-core"
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${MODULE_NAME1}: Tests Failed ------------------"
    exit 2
else
    echo "------------------ ${MODULE_NAME1}: Tests Passed ------------------"
fi

# -------------------------------
# Run Tests for swagger-parser-v3 Module
# -------------------------------
cd "../swagger-parser-v3"
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${MODULE_NAME2}: Tests Failed ------------------"
    exit 2
else
    echo "------------------ ${MODULE_NAME2}: Tests Passed ------------------"
fi
echo "PASS: ${MODULE_NAME1} version $PACKAGE_VERSION built and tested successfully."
echo "PASS: ${MODULE_NAME2} version $PACKAGE_VERSION built and tested successfully."
exit 0
